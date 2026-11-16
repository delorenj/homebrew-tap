# DeLorenzo Homebrew Tap

Homebrew formulas and casks for DeLorenzo software.

```sh
brew tap delorenj/tap
```

| Formula | Install |
| --- | --- |
| Vinyl macOS thin client (formula) | `brew install delorenj/tap/vinyl-client` |
| Vinyl macOS server, a Mac that runs its own dictation server (formula) | `brew install delorenj/tap/vinyl-server` |
| HeyMa menu-bar app (cask) | `brew install --cask delorenj/tap/heyma` |

Vinyl is a local microphone and text-injection client for a paired Vinyl
recognition server. Configure its server and pairing token before starting it:

```sh
mkdir -p ~/.config/vinyl
scp vinyl-server:~/.config/vinyl/server.token ~/.config/vinyl/token
vinyl setup --server vinyl-server:7733
brew services start vinyl-client
```

### Mac as its own server

`vinyl-server` lets a Mac decode its own dictation, so audio never leaves it. It
installs only a `vinyl-server` command and a `sh.delo.vinyl.server` service that
binds `127.0.0.1:7733`. Run setup once (it downloads and verifies both models,
mints `~/.config/vinyl/server.token` and pairs this Mac's client to the local
server), then start the service. Pair the client formula to it:

```sh
brew install delorenj/tap/vinyl-server
vinyl-server setup
brew services start vinyl-server

brew install delorenj/tap/vinyl-client
vinyl setup --server 127.0.0.1:7733
brew services start vinyl-client
```

Upgrades keep the token and the models. `vinyl-server doctor` checks the install;
the service logs to `$(brew --prefix)/var/log/vinyl-server.log`.

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
