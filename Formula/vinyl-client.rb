class VinylClient < Formula
  desc "Live dictation thin client for macOS"
  homepage "https://github.com/delorenj/vinyl-client-releases"
  url "https://github.com/delorenj/vinyl-client-releases/releases/download/v0.5.1/vinyl-client_0.5.1_macos.tar.gz"
  version "0.5.1"
  sha256 "eed4a45e01b7c5b6d78499b671e2fd5c6be138513b1262ff9dbfae0c5cafa248"

  on_macos do
    depends_on "python@3.13"
  end

  resource "homebrew-wheelhouse" do
    url "https://github.com/delorenj/vinyl-client-releases/releases/download/v0.5.1/vinyl-client_0.5.1_homebrew-wheelhouse.tar.gz"
    sha256 "e5fa254fd6e8e96ce17531ace08752e9b3b1959ab1e1d2dca0c7c97f7c36c838"
  end

  def install
    odie "vinyl-client is macOS-only" unless OS.mac?

    # Homebrew strips a single archive root while staging, so the payload is
    # directly under buildpath even though the release tarball has a named
    # top-level directory.
    package_root = buildpath
    unless (package_root/"CLIENT_ONLY").file? && (package_root/"bin/vinyl").file?
      odie "release archive is missing the Vinyl client payload"
    end

    package_root.children.each { |child| libexec.install child }
    python = Formula["python@3.13"].opt_bin/"python3.13"
    system python, "-m", "venv", libexec/"venv"

    resource("homebrew-wheelhouse").stage do
      arch = Hardware::CPU.arm? ? "arm64" : "x86_64"
      # Resource staging follows the same root-stripping rule. Keep the
      # fallback for a manually extracted wheelhouse during local debugging.
      wheel_root = Dir.exist?(arch) ? arch : Dir["*/#{arch}"].first
      odie "wheelhouse is missing #{arch} wheels" unless wheel_root

      wheels = Dir[File.join(wheel_root, "*.whl")].sort
      odie "wheelhouse contains no #{arch} wheels" if wheels.empty?
      system libexec/"venv/bin/python", "-m", "pip", "install",
             "--no-index", "--no-deps", *wheels
    end

    (bin/"vinyl").write <<~EOS
      #!/bin/sh
      export VINYL_HOMEBREW=1
      exec "#{libexec}/venv/bin/python" "#{libexec}/bin/vinyl" "$@"
    EOS
    (bin/"vinyl-toggle").write <<~EOS
      #!/bin/sh
      exec "#{opt_bin}/vinyl" toggle
    EOS
    chmod 0755, [bin/"vinyl", bin/"vinyl-toggle"]
  end

  service do
    name macos: "sh.delo.vinyl.client"
    run [opt_bin/"vinyl", "client"]
    keep_alive true
  end

  def caveats
    <<~EOS
      Configure a Vinyl server and copy its pairing token before starting the client:
        mkdir -p ~/.config/vinyl
        scp vinyl-server:~/.config/vinyl/server.token ~/.config/vinyl/token
        vinyl setup --server vinyl-server:7733
        brew services start vinyl-client

      The first dictation requires macOS Microphone and Accessibility permission.
      Bind `vinyl-toggle` with your preferred macOS shortcut manager.
      Native menu-bar/settings UI, installed into /Applications:
        brew install --cask delorenj/tap/heyma
      Do not run the direct installer over a Brew-managed client.

      To dictate against this Mac's own server instead (audio never leaves it):
        brew install delorenj/tap/vinyl-server
      Already paired to a remote server and want to keep that pairing valid?
      Copy its server.token to ~/.config/vinyl/server.token (0600) BEFORE
      `vinyl-server setup`, so both servers accept the one client token.
    EOS
  end

  test do
    help = shell_output("#{bin}/vinyl --help")
    assert_match "{client,setup,doctor,toggle,start,stop,cancel,status,trace,fix,prominence,polish}", help
    raise "client archive advertised recognizer modes" if help.include?("{daemon")
    assert_match "trace", shell_output("#{bin}/vinyl trace --help")
    assert_match "fix", shell_output("#{bin}/vinyl fix --help")
  end
end
