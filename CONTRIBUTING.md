# Contributing and Reporting Problems

Please keep documentation and examples in English. Prefer small, reversible troubleshooting steps and clearly separate build-specific observations from documented product behavior.

Before posting, read [PRIVACY.md](docs/PRIVACY.md). Do not attach your complete Codex configuration, authentication cache, proxy subscription, or raw log directory.

## Public issue template

```text
Windows version:
Codex desktop version:
Proxy application and version (no provider/account details):
Proxy type: HTTP / mixed / SOCKS / TUN
System proxy enabled: yes / no / managed
Browser works: yes / no
VS Code extension works: yes / no / not tested
Credential-free HTTPS probe result: status/timeout category only
Desktop WebSocket: connected / handshake failed / unknown
Full error category, with identifiers and personal values redacted:
Steps tried and the result of each:
Did a full desktop restart and the originally failing operation succeed?
```

Do not include a real request identifier in a public issue. Preserve it for private support if requested.

For changes to the launcher, verify Windows PowerShell 5.1 syntax, reject credential-bearing/non-loopback URLs, preserve certificate verification, and avoid global settings changes or forced termination of an active chat.
