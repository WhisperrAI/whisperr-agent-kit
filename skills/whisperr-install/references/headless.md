# Install without a browser (cloud agents, CI, headless runs)

The Whisperr MCP server signs in through the browser. An agent that runs
where no browser can open (a cloud agent, a CI job, `claude -p`) uses an
**install token** instead.

1. A workspace owner or admin creates the token in the Whisperr dashboard:
   **Integrations → Your code → Coding agent → Agent without a browser →
   Create install token**. It is shown once and starts with `wit_`.
2. Store it as the secret `WHISPERR_INSTALL_TOKEN` where the agent runs (the
   CI secret store, the cloud agent's environment settings). Never commit it
   or paste it into a file in the repository.
3. Connect the agent to the install-only server
   `https://mcp.whisperr.net/install` with the header
   `Authorization: Bearer <token>`. The configs below read the token from the
   environment.

What the token allows:

- One Whisperr app and the install tools only. It does not work on
  `https://mcp.whisperr.net/mcp`.
- One install. After the first successful `commit_registration` the token
  can only read (for example `get_received_events`, `get_setup_status`).
- It expires (by default 60 minutes after it was created), and an owner or
  admin can revoke it at any time in the dashboard.

Install tools still need the `wpk_` publishable key from the copy prompt as
`publishable_key`; Whisperr refuses a key from another app.

## Claude Code

Project `.mcp.json` (Claude Code expands `${WHISPERR_INSTALL_TOKEN}` from
the environment):

```json
{
  "mcpServers": {
    "whisperr": {
      "type": "http",
      "url": "https://mcp.whisperr.net/install",
      "headers": { "Authorization": "Bearer ${WHISPERR_INSTALL_TOKEN}" }
    }
  }
}
```

## Codex

`~/.codex/config.toml`:

```toml
[mcp_servers.whisperr]
url = "https://mcp.whisperr.net/install"
bearer_token_env_var = "WHISPERR_INSTALL_TOKEN"
```

## Cursor

`.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "whisperr": {
      "url": "https://mcp.whisperr.net/install",
      "headers": { "Authorization": "Bearer ${env:WHISPERR_INSTALL_TOKEN}" }
    }
  }
}
```

## Any agent with a shell (no MCP client)

The server answers plain JSON-RPC over HTTP, one request per call, without
a session. `tools/list` lists the tools; `tools/call` runs one, and its
result is in `result.structuredContent`:

```bash
curl -sS https://mcp.whisperr.net/install \
  -H "Authorization: Bearer $WHISPERR_INSTALL_TOKEN" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_required_events","arguments":{"publishable_key":"wpk_..."}}}'
```

The token is expanded into the `curl` command line. In CI, turn off shell
tracing (`set +x`) around the call so the log never shows it.

A `401` with `error="invalid_token"` means the token is wrong, expired,
revoked, or its creator is no longer an owner or admin: ask the user for a
new one. A `429` means wait for the `Retry-After` seconds.
