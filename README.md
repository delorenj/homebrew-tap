# DeLorenzo Homebrew Tap

```sh
brew tap delorenj/tap
```

| Formula | Install |
| --- | --- |
| Vinyl macOS thin client | `brew install vinyl-client` |

Vinyl is a local microphone and text-injection client for a paired Vinyl
recognition server. Configure its server and pairing token before starting it:

```sh
mkdir -p ~/.config/vinyl
scp vinyl-server:~/.config/vinyl/server.token ~/.config/vinyl/token
vinyl setup --server vinyl-server:7733
brew services start vinyl-client
```
Homebrew formulas for DeLorenzo software
