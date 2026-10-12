# Frequently Asked Questions

## Why can the browser and VS Code work while the desktop app fails?

They are different processes and can inherit different environments, use different proxy-resolution paths, or hold different connection state. A successful browser session does not verify the desktop process's request to the OAuth token endpoint. Compare the active system proxy, launch environment, and desktop logs before blaming the account.

## Does `https://` in the destination require an `https://` proxy URL?

Not necessarily. A local HTTP proxy commonly tunnels an HTTPS destination using HTTP CONNECT. Its address can be `http://127.0.0.1:<port>` while the destination is `https://auth.openai.com`. Use the scheme required by your proxy listener, not the scheme of the destination.

## Is the default port always the same?

No. Different proxy applications, profiles, and installations can use different ports. A historical default is not evidence about the listener currently running. Check the configured HTTP/mixed port and the process owning that listener.

## Is enabling TUN enough?

TUN may make many applications reachable, but it does not prove that the desktop login process, embedded web views, and WebSocket clients all have a working route. A process can still carry an obsolete explicit proxy. Diagnose the actual combination instead of treating either TUN or a system proxy as a universal cure.

## Do I have to edit `.env`?

Only if your workflow already uses it or your particular client loads it. Keep its proxy values consistent, but do not assume editing it will replace the environment of an existing desktop process. The generic launcher deliberately supplies the settings directly to a new process and does not write the file.

## Should I add both proxy feature flags to every installation?

No. The guide reports names seen in some builds. Check your client version and feature list, preserve the existing table, and distinguish an under-development flag from a documented stable setting. An unsupported, ignored, or already-enabled key may do nothing.

## Why does changing variables in PowerShell not immediately fix the desktop?

Those assignments belong to that PowerShell process and its future children. A desktop app already started from Explorer or another terminal keeps its existing environment. Completely exit it, then launch it through the intended path. Apply the same reasoning to VS Code after a proxy change.

## Should I set proxy variables globally for my Windows account?

Prefer a working system proxy and a process-scoped launch when that is sufficient. Global variables can affect package managers, dataset downloads, and unrelated tools. If you do need persistent variables, record their previous values and understand which applications will inherit them on their next start.

## Does a 400, 401, or 405 mean everything is fixed?

No. An expected rejection from a credential-free probe can establish an HTTP round trip. It does not prove valid login, model access, a successful WebSocket upgrade, or a complete streamed response. Confirm sign-in and the originally failing operation in the real desktop app.

## What if short HTTPS tests pass but WebSockets keep reconnecting?

Inspect the actual handshake failure and its time. Possibilities include intermittent upstream connectivity, filtering of WebSocket traffic, proxy-resolution differences, and service problems. A 1006 close code is not enough to choose among them. Test another known-working connection only after confirming that the local endpoint is correct.

## Can I solve every `stream disconnected` error with a network setting?

No. Read the full message. A transport error, response-body decoding error, and explicit server request-processing error can all appear under a similar wrapper. Preserve evidence and avoid declaring a service-side compaction failure fixed because a local HTTPS probe succeeds.

## Should I clear login files or reinstall immediately?

An initial network or token-endpoint failure is not sufficient reason to erase authentication state, conversations, or configuration. First verify the listener, effective proxy settings, process environment, trust configuration, and logs. Destructive cleanup can lose useful evidence without fixing the route.

## Does the launcher install a background service or choose a proxy provider?

No. It takes an explicit loopback HTTP proxy URL, checks whether that listener accepts a TCP connection, and starts the existing desktop app with matching process settings. It does not establish that the upstream connection is healthy. Start and configure your proxy application yourself.

## Can I open an issue with my logs?

Use the reporting template in [CONTRIBUTING.md](../CONTRIBUTING.md). Share only a sanitized excerpt. Keep OAuth tokens, auth caches, account identifiers, request identifiers, subscription URLs, private paths, and certificate material out of a public issue.
