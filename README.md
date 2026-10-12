# Fixing Codex Desktop Sign-In and Proxy Issues on Windows

A practical troubleshooting guide for Codex Desktop sign-in failures and proxy-related reconnects on Windows. The focus is consistent proxy configuration, reversible changes, and verification of the actual desktop connection.

This is a community guide, not an official OpenAI product or a guarantee against future outages. A local proxy repair cannot prevent every server-side error or failed context-compaction request.

## The problem this guide addresses

You may be able to use ChatGPT in a browser and Codex in VS Code while the desktop app fails with:

```text
Sign-in failed
Token exchange failed: error sending request for url
https://auth.openai.com/oauth/token
```

Other symptoms include repeated `Reconnecting`, `Waiting for work`, or a WebSocket that closes before its connection is established.

In an anonymized troubleshooting case, aligning the Windows system proxy with the working local HTTP proxy and launching the desktop app with matching proxy settings restored sign-in. Later tests also showed that a correctly configured proxy could still have intermittent connection failures. The configuration fix and the reliability of the proxy's upstream connection are separate questions.

No personal logs, credentials, screenshots, certificate bundles, device identifiers, or private project paths are included in this repository.

## Start here

1. Start your proxy application and select a working connection.
2. Find its **HTTP or mixed proxy port**, not a SOCKS-only port. Every `8080` below is a placeholder: replace it with your own port.
3. Enable the proxy application's Windows **system proxy** option. Use its local listener, normally `127.0.0.1:<port>`.
4. Check that any existing proxy environment settings use the same port.
5. Fully quit Codex from the system tray, then reopen it. Closing its window may leave its background processes running.
6. Retry sign-in and verify the real desktop connection, not just a website or a short HTTP request.

If the normal launch still uses a different network path, try the optional [process-scoped launcher](#optional-process-scoped-launcher).

## 1. Identify the failure before changing settings

| Symptom | What it tells you | First check |
| --- | --- | --- |
| Browser sign-in succeeds, then token exchange fails | The desktop login process failed while contacting the token endpoint; it does not establish that the account is invalid | Desktop proxy path, TLS trust, and token-endpoint reachability |
| `ERR_PROXY_CONNECTION_FAILED` | A client failed to use its configured proxy | Is that proxy still listening at the configured address? |
| WebSocket `1006`, `open_timeout`, or closed before connection establishment | A handshake or connection failed; code 1006 alone does not identify the cause | Proxy consistency, filtering, upstream reliability, and desktop logs |
| `stream disconnected ... error decoding response body` | A streamed response did not finish correctly | Preserve the complete error; inspect whether it contains a transport error or a server error |
| Remote compaction reports a request-processing error | A compaction operation failed with an error message; this is not proof that the local proxy is wrong | Retry carefully, preserve the request identifier privately, and inspect the surrounding connection state |

The words `stream disconnected` are a wrapper, not a complete diagnosis. The text after them matters. Do not classify a request as HTTP 500 unless a response or log actually establishes its status.

## 2. Check the Windows system proxy and local listener

Run these commands in **your normal Windows desktop account**. A sandbox, service, different account, or WSL session may see different settings. `HKCU` refers to the account executing the command.

```powershell
$internetSettings = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
Get-ItemProperty -LiteralPath $internetSettings |
    Select-Object ProxyEnable, ProxyServer, AutoConfigURL

$proxyPort = 8080 # Example only: replace with your HTTP/mixed port.
Get-NetTCPConnection -State Listen -LocalPort $proxyPort |
    Select-Object LocalAddress, LocalPort, OwningProcess
```

Inspect this output locally. A typical explicit configuration has `ProxyEnable = 1` and an HTTP/HTTPS proxy pointing to the actual local listener. PAC-managed and organization-managed machines may use different mechanisms; do not replace their settings blindly.

If needed, identify the owning process:

```powershell
$proxyListeners = Get-NetTCPConnection -State Listen -LocalPort $proxyPort
$proxyProcessIds = $proxyListeners.OwningProcess | Sort-Object -Unique
Get-Process -Id $proxyProcessIds | Select-Object Id, ProcessName
```

An installed background service is not evidence that a usable HTTP proxy is running. A listening port is also not sufficient unless it supports the protocol you intend to use.

### HTTP proxy, SOCKS, and TUN are different

- HTTP and mixed ports can normally accept HTTP CONNECT for HTTPS destinations.
- A SOCKS-only port must use SOCKS configuration. Do not put it behind an `http://` proxy URL.
- TUN routes traffic at another layer. Enabling TUN does not establish that every desktop component has the intended proxy settings.
- A virtual adapter's address is not automatically the application's local HTTP proxy address.

For an unmanaged personal machine, prefer the proxy application's own system-proxy toggle over editing registry values manually. This keeps its saved preferences and the Windows setting aligned.

## 3. Keep environment settings consistent

Use one local HTTP endpoint consistently. A process-scoped PowerShell example is:

```powershell
$proxyUri = 'http://127.0.0.1:8080' # Example only.
$env:HTTP_PROXY = $proxyUri
$env:HTTPS_PROXY = $proxyUri
$env:ALL_PROXY = $proxyUri
$env:NO_PROXY = 'localhost,127.0.0.1,::1'
```

These assignments affect that PowerShell process and programs started from it. They do **not** automatically update an already-running desktop app, VS Code, or Explorer.

Existing user-level or machine-level variables can override expectations. Inspect only the variables relevant to networking rather than dumping your entire environment:

```powershell
$proxyKeys = 'HTTP_PROXY','HTTPS_PROXY','ALL_PROXY','NO_PROXY'
foreach ($scope in 'User','Machine','Process') {
    foreach ($key in $proxyKeys) {
        $value = [Environment]::GetEnvironmentVariable($key, $scope)
        if ($null -ne $value) {
            [pscustomobject]@{ Scope=$scope; Name=$key; Value=$value }
        }
    }
}
```

Keep this output private if it contains internal hosts or a credential-bearing proxy URL. Avoid adding persistent global proxy variables when a process-scoped setup is sufficient: they can affect unrelated downloads and development tools.

### What about `.env`?

Some Codex configurations or launch workflows use a file under the Codex home directory. If you already use one, its proxy entries should agree with the actual listener:

```dotenv
HTTP_PROXY=http://127.0.0.1:8080
HTTPS_PROXY=http://127.0.0.1:8080
ALL_PROXY=http://127.0.0.1:8080
NO_PROXY=localhost,127.0.0.1,::1
```

See [the sanitized example](examples/proxy.env.example). Do not replace your entire existing file; preserve unrelated settings and deliberate bypass rules.

A `.env` file is **not a universal Windows app configuration mechanism**. Whether it is loaded, and how it interacts with inherited variables, depends on the client and launch workflow. Explicitly passing the environment to a new desktop process is easier to verify than assuming a file was consumed.

Keep loopback addresses outside the upstream proxy so local callbacks can work. Do not bypass OpenAI domains unintentionally, and do not use `NO_PROXY=*` as a generic repair.

## 4. Treat Codex feature flags as build-specific

The native Windows Codex home normally contains `config.toml` under `%USERPROFILE%\.codex`; a custom `CODEX_HOME` changes that location. Use the app's configuration controls or the active configuration file. See [OpenAI Docs: Windows app](https://learn.chatgpt.com/docs/windows/windows-app) and [configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference).

Some observed builds expose proxy-related feature flags. Check the CLI actually associated with your client:

```powershell
codex --version
codex features list |
    Select-String -Pattern 'respect_system_proxy|system_proxy_fallback'
```

Do not assume a CLI found on `PATH` is the exact executable bundled with the desktop app or VS Code extension.

Only if your build recognizes the relevant keys, an existing `[features]` table can contain:

```toml
[features]
respect_system_proxy = true
system_proxy_fallback = true
```

In one observed build, `respect_system_proxy` was labeled **under development**, while `system_proxy_fallback` was labeled **stable**. These names were not found in the public configuration reference checked for this guide. They are build-specific observations, not universally documented settings or a guaranteed fix. A flag already enabled by default may add no new behavior.

Merge supported settings into the existing table; do not create duplicate `[features]` tables. Back up your own configuration outside this repository before changing it. Preserve model, permissions, project, and plugin settings. Do not disable sandboxing to solve a login transport problem.

## Optional process-scoped launcher

The [generic launcher](scripts/Start-CodexWithProxy.ps1) starts the existing Codex desktop app with an explicit local HTTP proxy. It does not choose a provider, install autostart entries, modify the registry, write `.env`, or change `config.toml`.

Start your proxy first, fully quit Codex, and run:

```powershell
powershell.exe -NoProfile -File .\scripts\Start-CodexWithProxy.ps1 `
    -ProxyUrl 'http://127.0.0.1:8080'
```

The script resolves the currently installed `OpenAI.Codex` Windows package instead of hard-coding a package-version directory. For a different installation layout, provide your own executable:

```powershell
powershell.exe -NoProfile -File .\scripts\Start-CodexWithProxy.ps1 `
    -ProxyUrl 'http://127.0.0.1:8080' `
    -ExecutablePath 'C:\Path\To\Codex\ChatGPT.exe'
```

`C:\Path\To\Codex\ChatGPT.exe` is a placeholder, not a real installation path. The script uses a Chromium proxy launch argument observed to work in the tested desktop app; compatibility can change with future client versions.

If PowerShell blocks an unsigned script, review it first and follow your organization's execution policy. Do not permanently relax system-wide policy to run a troubleshooting script. You can also enter the reviewed process-scoped environment assignments and launch command manually in an interactive PowerShell session.

### Changing proxy software or ports

Close the unused proxy, start the intended one, and find its current HTTP/mixed port. Update the system-proxy setting and any launch environment or existing `.env` entries that still refer to the old endpoint. Restart Codex and any VS Code process holding the previous environment.

A generic startup sequence is: **start the chosen proxy → wait for its listener → launch Codex with that endpoint**. An adaptive launcher needs explicit support for each proxy's process/configuration conventions; it should not guess from a service name or a historical default port.

## 5. Verify transport without exposing credentials

Use `curl.exe` explicitly in Windows PowerShell; `curl` may be an alias in some shells. These probes deliberately send no account token or authorization code:

```powershell
$proxyUri = 'http://127.0.0.1:8080' # Example only.

curl.exe --proxy $proxyUri --noproxy 'localhost,127.0.0.1,::1' --connect-timeout 8 --max-time 15 `
    --silent --show-error -o NUL `
    -w 'auth_http=%{http_code} tls=%{time_appconnect} total=%{time_total}\n' `
    https://auth.openai.com/oauth/token

curl.exe --proxy $proxyUri --noproxy 'localhost,127.0.0.1,::1' --connect-timeout 8 --max-time 15 `
    --silent --show-error -o NUL `
    -w 'codex_http=%{http_code} tls=%{time_appconnect} total=%{time_total}\n' `
    https://chatgpt.com/backend-api/codex/models
```

The explicit `--noproxy` list keeps loopback bypasses without inheriting a rule that could send the OpenAI probes directly. The backend URL is an observed client endpoint, not a stable public API contract. It may change or be unavailable in another release. Use these results as diagnostics rather than a health API.

| Result | Interpretation |
| --- | --- |
| Token endpoint responds with 405 to GET | HTTPS reached a server that rejected the method; this is not a successful OAuth token exchange |
| Protected backend responds with 401 | An HTTP response was received without credentials; this is not proof of account access or successful inference |
| 403 | The request was rejected; inspect the response and any access/filtering restrictions |
| `http_code=000`, timeout, reset, or TLS error | No complete HTTP response was received; investigate the proxy path or TLS stack |
| Successful TLS handshake | The tested client trusts that connection; another client may use different trust settings |

Never use `-k` or disable certificate verification as the normal solution. If Windows curl reports a TLS-stack-specific error such as `SEC_E_NO_CREDENTIALS`, compare another properly validating TLS client before assigning the cause to the proxy.

### The actual desktop test is essential

After short probes, verify:

- Browser authorization returns to the desktop app and sign-in completes.
- The relevant desktop connection reaches a connected state.
- A real conversation finishes a response, including any needed tool round trip.
- The operation that originally failed succeeds, such as a sustained stream or context compaction.
- After a normal restart, the proxy is still available before Codex starts.

A browser page, a fast 401, or several successful HTTPS probes do not establish long-stream or WebSocket reliability. An upstream connection can pass a short test and still fail later.

## 6. Check logs locally

One observed Windows app log location is `%LOCALAPPDATA%\Codex\Logs`. Locations and internal labels vary by release. Direct CLI login also has login-specific diagnostics; see [OpenAI Docs: Authentication](https://learn.chatgpt.com/docs/auth).

```powershell
$logRoot = Join-Path $env:LOCALAPPDATA 'Codex\Logs'
$latestLogs = Get-ChildItem -LiteralPath $logRoot -Recurse -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 3

foreach ($log in $latestLogs) {
    Select-String -LiteralPath $log.FullName -Encoding UTF8 `
        -Pattern 'websocket_error|open_timeout|reconnect_started|ERR_PROXY_CONNECTION_FAILED|Token exchange failed' |
        Select-Object -Last 10
}
```

Inspect locally and compare timestamps around the failure. Some builds label a remote app-server connection `durable`; this is an internal log label, not a setting to change. No matching lines does not prove that all streams succeeded or that all relevant logs were inspected.

Do not upload raw logs or your entire Codex home directory. They may contain usernames, workspace paths, conversation identifiers, account metadata, and task content. See [the privacy checklist](docs/PRIVACY.md).

## 7. Keep TLS repairs targeted

If a trusted organization requires a private root certificate or TLS interception, obtain the correct CA bundle from its administrator. Set `CODEX_CA_CERTIFICATE` for the client only when that trust configuration is actually needed. `SSL_CERT_FILE` is a documented fallback when that variable is unset. See [OpenAI Docs: Environment variables](https://learn.chatgpt.com/docs/config-file/environment-variables).

Do not download arbitrary CA bundles from troubleshooting posts, copy certificates from unrelated software without understanding their origin, or treat a token-exchange network error as proof of a certificate problem. A custom CA bundle is not a substitute for a working proxy.

Do not publish your actual certificate bundle, private key, or credential file in this repository.

## 8. Handle remote-compaction errors separately

Long conversations may need remote context compaction. A compaction request can fail even when login, ordinary HTTPS traffic, and the desktop WebSocket are working.

If the full message says that an error occurred while processing the request and includes a request identifier, preserve it privately. This points toward a request-processing problem, but the message alone does not establish its HTTP status, internal cause, or whether every surrounding network operation was healthy.

Retry once after a brief wait. Before continuing tool work, check whether the last command already ran: an interrupted response does not necessarily mean that the command was never executed. Preserve completed files and experiment state rather than repeating side-effecting work blindly.

If the failure persists, provide the complete sanitized error and the request identifier through an appropriate private support channel. See [OpenAI Docs: Error codes](https://developers.openai.com/api/docs/guides/error-codes) and [Compaction](https://developers.openai.com/api/docs/guides/compaction). A larger retry count or another proxy environment variable cannot guarantee a repair for a service-side failure.

## Reversibility and ongoing use

Change one thing at a time and keep local backups outside the repository. Record the previous proxy endpoint and modified settings without saving tokens. A normal proxy repair does not require deleting conversations, datasets, models, `auth.json`, or the full Codex home.

If you created custom startup entries, keep only the ones you understand. Provider-specific autostart settings can unexpectedly start an old proxy after you switch software. Never stop a currently working application or remove an existing startup entry without checking its origin.

For additional explanations, see [FAQ](docs/FAQ.md). Before opening an issue, read [the contribution and reporting guide](CONTRIBUTING.md).

## References

- [OpenAI Docs: Authentication](https://learn.chatgpt.com/docs/auth)
- [OpenAI Docs: Windows desktop app](https://learn.chatgpt.com/docs/windows/windows-app)
- [OpenAI Docs: Configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference)
- [OpenAI Docs: Environment variables](https://learn.chatgpt.com/docs/config-file/environment-variables)
- [OpenAI Docs: Error codes](https://developers.openai.com/api/docs/guides/error-codes)
- [OpenAI Docs: Compaction](https://developers.openai.com/api/docs/guides/compaction)

Public documentation supports the product guidance linked above. Proxy flags, Chromium launch arguments, client endpoints, and internal log labels described as observations must be rechecked against the installed build.
