class VinylServer < Formula
  desc "Live dictation server for macOS (a Mac that runs its own Vinyl serve)"
  homepage "https://github.com/delorenj/vinyl-client-releases"
  url "https://github.com/delorenj/vinyl-client-releases/releases/download/vinyl-server-v0.5.1/vinyl-server_0.5.1_macos.tar.gz"
  sha256 "75767a6544dc719b07306214456c9561adfd1efacfc86119b5587f43d618efd8"

  depends_on :macos
  depends_on "python@3.13"

  resource "homebrew-wheelhouse" do
    url "https://github.com/delorenj/vinyl-client-releases/releases/download/vinyl-server-v0.5.1/vinyl-server_0.5.1_homebrew-wheelhouse.tar.gz"
    sha256 "1c6f1d18de65c4844b83ae00f0c4c27af95479bee4bf46746d6f6e64ac66d68f"
  end

  def install
    # Homebrew strips a single archive root while staging, so the payload is
    # directly under buildpath even though the release tarball has a named
    # top-level directory.
    package_root = buildpath
    server_payload = (package_root/"SERVER").file? &&
                     (package_root/"bin/vinyl").file? &&
                     (package_root/"bin/download-model").file?
    if !server_payload || (package_root/"CLIENT_ONLY").exist?
      odie "release archive is not a Vinyl server payload " \
           "(needs SERVER, bin/vinyl and bin/download-model, and no CLIENT_ONLY)"
    end

    # The whole payload goes into libexec: `vinyl-server setup` runs
    # <payload>/bin/download-model.
    package_root.children.each { |child| libexec.install child }
    python = formula_opt_bin("python@3.13")/"python3.13"
    system python, "-m", "venv", libexec/"venv"

    resource("homebrew-wheelhouse").stage do
      arch = Hardware::CPU.arm? ? "arm64" : "x86_64"
      # Resource staging follows the same root-stripping rule. Keep the
      # fallback for a manually extracted wheelhouse during local debugging.
      wheel_root = Dir.exist?(arch) ? arch : Dir["*/#{arch}"].first
      odie "wheelhouse is missing #{arch} wheels" unless wheel_root

      wheels = Dir[File.join(wheel_root, "*.whl")]
      odie "wheelhouse contains no #{arch} wheels" if wheels.empty?
      system libexec/"venv/bin/python", "-m", "pip", "install",
             "--no-index", "--no-deps", *wheels
    end

    (bin/"vinyl-server").write <<~EOS
      #!/bin/sh
      export VINYL_HOMEBREW=1
      exec "#{libexec}/venv/bin/python" "#{libexec}/bin/vinyl" "$@"
    EOS
    chmod 0755, bin/"vinyl-server"
  end

  service do
    name macos: "sh.delo.vinyl.server"
    run [opt_bin/"vinyl-server", "serve", "--host", "127.0.0.1", "--port", "7733"]
    keep_alive true
    log_path var/"log/vinyl-server.log"
    error_log_path var/"log/vinyl-server.log"
  end

  def caveats
    <<~EOS
      This Mac runs its own Vinyl dictation server, bound to 127.0.0.1:7733 only.
      Run setup once before starting the service. It downloads and verifies both
      pinned models, mints ~/.config/vinyl/server.token and pairs this Mac's
      own client to 127.0.0.1:7733:
        vinyl-server setup
        brew services start vinyl-server

      `vinyl-server setup` already pairs the client. With the client formula
      installed, start it:
        brew services start vinyl-client
      `vinyl setup --server 127.0.0.1:7733` (client formula) is only needed to
      re-pair a client that was pointed at another server, and is harmless to rerun.

      A client already paired to another server (big-chungus) keeps that pairing:
      setup seeds server.token from the client's existing token, so one token works
      on both. Switch back with `vinyl setup --server HOST:PORT`, then
      `brew services restart vinyl-client`.

      The service always uses the default model directory, ~/audio/models (brew
      services does not pass your shell environment). To keep models elsewhere,
      symlink ~/audio/models to that directory rather than setting VINYL_MODEL_DIR.

      Upgrades keep ~/.config/vinyl (the token and pairing) and the models. Restart
      the service after an upgrade when you are not dictating:
        brew services restart vinyl-server

      Check the install with:
        vinyl-server doctor
      Service log: #{var}/log/vinyl-server.log
    EOS
  end

  test do
    assert_equal ["vinyl-server"], bin.children.map { |path| path.basename.to_s }

    help = shell_output("#{bin}/vinyl-server --help")
    assert_match "vinyl-server", help
    assert_match "{serve,", help
    refute_match(/[{,](daemon|client)[,}]/, help)

    backends = shell_output(
      "#{libexec}/venv/bin/python -c 'import transcribe_cpp; print(transcribe_cpp.backends())'",
    )
    puts backends
    # CPU is always listed. Never assert Metal: hosted runners may not expose it.
    assert_match(/kind=['"]cpu['"]/, backends)

    # No model, no network: serve must refuse and name the missing file.
    model_root = testpath/"models"
    model_root.mkpath
    with_env(VINYL_MODEL_DIR: model_root.to_s) do
      output = shell_output("#{bin}/vinyl-server serve --host 127.0.0.1 --port 17733 2>&1", 1)
      assert_match "missing model file", output
      assert_match "parakeet-tdt-0.6b-v3-Q8_0.gguf", output
      assert_match "run `vinyl-server setup`", output
      refute_match "Traceback", output
    end
  end
end
