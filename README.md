# DeLorenzo Homebrew Tap

```sh
brew tap delorenj/tap
```

| Formula | Install |
| --- | --- |
| Vinyl macOS thin client (formula) | `brew install vinyl-client` |
| HeyMa menu-bar app (cask) | `brew install --cask heyma` |

Vinyl is a local microphone and text-injection client for a paired Vinyl
recognition server. Configure its server and pairing token before starting it:

```sh
mkdir -p ~/.config/vinyl
scp vinyl-server:~/.config/vinyl/server.token ~/.config/vinyl/token
vinyl setup --server vinyl-server:7733
brew services start vinyl-client
```
Homebrew formulas for DeLorenzo software

HeyMa is the native menu-bar and settings app for that client. The cask installs
`HeyMa.app` into `/Applications`; it needs a configured client (Brew or the
direct installer) and does not install one itself:

```sh
brew install --cask heyma
```

The app is ad-hoc signed, not notarized; the cask clears the download
quarantine so it opens normally.
