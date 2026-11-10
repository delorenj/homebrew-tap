# DeLorenzo Homebrew Tap

Homebrew formulas and casks for DeLorenzo software.

```sh
brew tap delorenj/tap
```

| Formula | Install |
| --- | --- |
| Vinyl macOS thin client (formula) | `brew install delorenj/tap/vinyl-client` |
| HeyMa menu-bar app (cask) | `brew install --cask delorenj/tap/heyma` |

Vinyl is a local microphone and text-injection client for a paired Vinyl
recognition server. Configure its server and pairing token before starting it:

```sh
mkdir -p ~/.config/vinyl
scp vinyl-server:~/.config/vinyl/server.token ~/.config/vinyl/token
vinyl setup --server vinyl-server:7733
brew services start vinyl-client
```

HeyMa is the native menu-bar and settings app for that client. The cask installs
`HeyMa.app` into `/Applications`; it needs a configured client (Brew or the
direct installer) and does not install one itself:

```sh
brew install --cask delorenj/tap/heyma
```

Use the full `delorenj/tap/...` names: current Homebrew only loads a
non-official tap's packages once trusted, and installing by full name trusts
them (or run `brew trust --tap delorenj/tap` once).

The app is ad-hoc signed, not notarized; the cask clears the download
quarantine so it opens normally.
