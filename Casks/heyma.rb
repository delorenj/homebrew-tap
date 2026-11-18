cask "heyma" do
  version "0.5.1"
  sha256 "9624a7f60dd17f6535a13c61ca46c2a8df7a55a49aedba2f261ec91f65d92b03"

  url "https://github.com/delorenj/vinyl-client-releases/releases/download/heyma-v#{version}/HeyMa-#{version}-macos-universal.zip"
  name "HeyMa"
  desc "Menu-bar shell for HeyMa: dictation, Vinyl and Phonograph"
  homepage "https://github.com/delorenj/vinyl-client-releases"

  # Client releases (v<ver>, vinyl-server-v<ver>) share this repo; only the
  # heyma-v<ver> tags are the app, whichever release GitHub marks Latest.
  livecheck do
    url :url
    regex(/^heyma-v(\d+(?:\.\d+)+)$/i)
    strategy :github_releases do |json, regex|
      json.filter_map do |release|
        next if release["draft"] || release["prerelease"]

        release["tag_name"]&.[](regex, 1)
      end
    end
  end

  depends_on macos: :ventura

  app "HeyMa.app"

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
    ~/Applications/HeyMa.app, quit it and remove it so only one HeyMa is
    registered. Its "Open HeyMa at login" agent still points at that old copy:
    open the new app's settings and toggle that option off and on again.
  EOS
end
