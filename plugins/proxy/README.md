# proxy

Handy's desktop system-proxy integration.

- Windows uses a Flutter method channel and WinINet settings.
- macOS uses `/usr/sbin/networksetup` for each active network service.

The public `Proxy` API validates the port, applies HTTP, HTTPS, and SOCKS
settings to `127.0.0.1`, and returns `false` when the selected platform backend
is unavailable or a command fails.
