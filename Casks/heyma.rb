cask "heyma" do
  version "0.4.3"
  sha256 "33eec78d91ffb93a816cf4d92752094da35a8f2f5427af22b3261b18d2c64f9a"

  url "https://github.com/delorenj/vinyl-client-releases/releases/download/v#{version}/HeyMa-#{version}-macos-universal.zip"
  name "HeyMa"
  desc "Menu-bar dictation control and settings for the Vinyl client"
  homepage "https://github.com/delorenj/vinyl-client-releases"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  app "HeyMa.app"

  # The bundle is ad-hoc signed, not notarized. Homebrew propagates the download
  # quarantine onto the staged bundle; clear it there, before the move into the
  # app directory, so the first launch is not blocked by Gatekeeper.
  preflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{staged_path}}/HeyMa.app"]
  end

  uninstall quit: "sh.delo.heyma"

  # The app's own "open at login" agent lives here; the Vinyl client's
  # sh.delo.vinyl.client agent belongs to the client install and is left alone.
  zap trash: [
    "~/Library/LaunchAgents/sh.delo.heyma.plist",
    "~/Library/Preferences/sh.delo.heyma.plist",
  ]

  caveats <<~EOS
    HeyMa is the UI only. It drives an installed Vinyl client, which owns the
    microphone and text injection. If this Mac has no client yet:
      brew install delorenj/tap/vinyl-client
    then follow that formula's caveats to pair it and start its service.

    A Mac that already runs the direct-installer client works as-is; do not add a
    Brew client next to it. If the direct installer put a copy at
    ~/Applications/HeyMa.app, remove it so only one HeyMa is registered.
  EOS
end
