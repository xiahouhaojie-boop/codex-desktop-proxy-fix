# Privacy Before Publishing Diagnostics

This repository intentionally contains general examples rather than personal troubleshooting artifacts. The same rule applies to pull requests, issues, and screenshots.

## Do not publish

- `auth.json`, OAuth authorization codes, access/refresh/ID tokens, cookies, or API keys.
- Your real `.env`, full `config.toml`, Codex home directory, or shell-history export.
- Proxy subscriptions, provider account information, controller secrets, node definitions, or passwords embedded in proxy URLs.
- Certificate bundles, private keys, client certificates, or unrelated trust-store exports.
- Raw app logs, session JSONL files, conversation exports, or configuration backups.
- Screenshots that reveal names, accounts, workspace titles, local paths, private network addresses, or identifiers.
- Your machine name, Windows account name/SID, real email address, private project locations, or conversation/request identifiers.

## Replace private values

| Original kind of information | Public replacement |
| --- | --- |
| Actual user profile path | `%USERPROFILE%` or `<USER_PROFILE>` |
| Actual application path | `C:\Path\To\Application\app.exe` |
| Personal proxy configuration | A synthetic `http://127.0.0.1:8080` example |
| Conversation or request identifier | `<REDACTED>` |
| Authorization/cookie header | Remove the complete value |
| Provider subscription URL | Remove the complete URL |

Request identifiers can help private support investigate a failure; they do not need to be posted publicly. Follow the private support channel's instructions and share only the information needed there.

## Before committing

Review the exact staged file list and diff:

```powershell
git diff --cached --name-only
git diff --cached --check
git diff --cached
```

Look at author metadata as well as file contents. If you want to keep your real email private, use the GitHub-provided noreply address for your account rather than assuming your global Git identity is suitable for a public commit.

The `.gitignore` reduces accidental inclusion of local artifacts. It does not redact file contents, protect already-tracked files, or replace a manual review. Do not use `git add .` on a directory containing your troubleshooting backups.
