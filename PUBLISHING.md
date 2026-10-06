# Publishing the Whisperr agent kit

Steps to list Whisperr in each agent directory. Checked against the vendor
docs on 2026-10-05; states updated 2026-10-06. "Owner" marks who must act:
**George** (account owner, attestations, DNS, payments) or **eng**.

## Before any directory

| # | Item | Owner | State |
|---|---|---|---|
| 0.1 | `https://mcp.whisperr.net/mcp` answers over HTTPS: `401` with `WWW-Authenticate: Bearer resource_metadata=…` when unauthenticated; OAuth 2.1 with CIMD and DCR; scopes `data:read`, `install:write`, `changes:propose`, `offline_access` | eng | Live |
| 0.2 | Every tool has `title` and `readOnlyHint` / `destructiveHint` / `idempotentHint` / `openWorldHint` | eng | Done (platform and integration tools) |
| 0.3 | Privacy policy `https://whisperr.net/privacy/` | George | Live (v1.0, 2026-10-05) |
| 0.4 | Terms `https://whisperr.net/terms/` | George | Live |
| 0.5 | Support page or address. The manifests use `https://github.com/WhisperrAI/whisperr-agent-kit/issues` until a `whisperr.net/support` page exists | George | Open |
| 0.6 | Demo workspace "Whisperr Demo" with sample data; email + password login; no MFA, no email code, no magic link | George | Open |
| 0.7 | Video walkthrough of the 5 positive test cases in `plugin.json` (needed by OpenAI) | George | Open |
| 0.8 | Self-test the server as a custom connector in Claude, ChatGPT developer mode, Claude Code, Codex and Cursor; run every test case. In Cursor, confirm that OAuth accepts its redirect URI | eng + George | Open |

## 1. Claude: connector + plugin (Anthropic directory)

Docs: https://claude.com/docs/plugins/submit ·
https://claude.com/docs/plugins/pre-submission-checklist ·
https://claude.com/docs/connectors/building/submission

Anthropic asks for both: the remote MCP server as a **connector**, and this
repo as a **plugin bundle**.

1. **George:** use a paid claude.ai plan (Team/Enterprise: an Owner). In the
   claude.ai organization that submits, connect the GitHub account that can
   push to `WhisperrAI/whisperr-agent-kit`.
2. **eng:** `claude plugin validate --strict .claude-plugin/plugin.json`
   (Claude Code 2.1.281 or later; older versions warn on the directory
   listing fields).
3. **George — connector:** https://claude.ai/directory/manage → **Submit
   new** → **MCP connector**. URL `https://mcp.whisperr.net/mcp`; auth
   OAuth (CIMD/DCR); name Whisperr; icon `assets/logo.png`; docs
   `https://docs.whisperr.net/agents/`; privacy `https://whisperr.net/privacy/`;
   support (0.5); 3+ example prompts (use the positive cases in
   `plugin.json`); test account (0.6); data-handling answers; the policy
   acknowledgements.
4. **George — plugin:** same portal → **Submit new** → **Plugin bundle**.
   Repository `WhisperrAI/whisperr-agent-kit`, plugin path empty (repo root),
   tracked branch `main`. Select **Validate**, fix every **Blocking**
   finding, then fill **Data handling** (reads personal data: no; sends data
   to services other than declared connectors: no; under 18: no) and the four
   acknowledgements. Keep **GitHub push webhook** and select **Submit for
   review**. Then **Set up push updates** (needs repo admin).
5. After approval select **Publish**. Later releases: raise `version`, merge
   to `main`; the directory scans each commit.

Self-hosted marketplace (works today, no review):
`/plugin marketplace add WhisperrAI/whisperr-agent-kit` then
`/plugin install whisperr@whisperr`.

## 2. OpenAI: ChatGPT + Codex plugin directory

Docs: https://developers.openai.com/plugins/build/plugins ·
https://developers.openai.com/plugins/deploy/submission

1. **George:** in https://platform.openai.com/settings/organization/general
   complete **business verification** for Whisperr. Submitters need the
   organization owner role or **Apps Management Write**.
2. **eng:** build the package: `./scripts/build-openai-zip.sh` →
   `dist/whisperr-openai-plugin.zip`. Each GitHub release `vX.Y.Z` also
   attaches this ZIP.
3. **George:** https://platform.openai.com/plugins → **Upload new or
   existing plugin** → choose the verified developer identity → upload the
   ZIP. Fix metadata and skill findings, then upload a corrected ZIP.
4. **George + eng — MCPs tab:** **Connect** the `whisperr` server. The
   portal shows a domain-verification token. **eng** serves it as plain text
   (only the token) at `https://mcp.whisperr.net/.well-known/openai-apps-challenge`.
   Then connect, complete OAuth with the demo account, and wait for the tool
   scan. Fix findings and **Rescan**.
5. **George — Review details:** the 5 positive and 3 negative test cases
   come from `plugin.json`. Add `review.demo_recording_url` to `plugin.json`
   (video 0.7) and upload again, or enter it in the dashboard. Enter the demo
   account credentials in the secure form (never in the ZIP).
6. **George:** **Submit for review**, accept the attestations. After
   approval select **Publish plugin**.
7. Later: skill or metadata changes need a new ZIP; MCP tool changes are
   rescanned from the server.

Codex without the directory (works today):
`codex plugin marketplace add WhisperrAI/whisperr-agent-kit` then
`codex plugin add whisperr@whisperr`.

## 3. Cursor Marketplace

Docs: https://cursor.com/docs/reference/plugins (section "Submitting a plugin")

1. The repo is public, MIT, and has `.cursor-plugin/plugin.json`, a committed
   logo (`assets/logo.svg`) and a README. Cursor reviews every update.
2. **George:** open https://cursor.com/marketplace/publish, sign in with the
   Whisperr Cursor account, submit `https://github.com/WhisperrAI/whisperr-agent-kit`.
3. Without the marketplace (works today): the "Add to Cursor" deeplink in
   the README.

## 4. Official MCP Registry (`net.whisperr/whisperr`)

**Done (2026-10-05).** `net.whisperr/whisperr` version 2.0.0 is published
and active. The namespace is proven with the DNS TXT record
`v=MCPv1; k=ed25519; p=FqPSEDDJMimZd8suHKCtWNPVZv30FHcUmYGe7nyKDh0=` on the
apex `whisperr.net`. The Ed25519 private key is on George's Mac at
`~/.config/whisperr/mcp-registry/key.pem` (mode 600, never commit it).

Docs: https://github.com/modelcontextprotocol/registry/blob/main/docs/modelcontextprotocol-io/authentication.mdx ·
https://github.com/modelcontextprotocol/registry/blob/main/docs/modelcontextprotocol-io/remote-servers.mdx

Check:
`curl "https://registry.modelcontextprotocol.io/v0/servers?search=net.whisperr/whisperr"`.

To publish a new version (versions are immutable), raise `version` in
`registry/server.json`, then:

```bash
PRIVATE_KEY="$(/opt/homebrew/opt/openssl@3/bin/openssl pkey -in ~/.config/whisperr/mcp-registry/key.pem -noout -text | grep -A3 "priv:" | tail -n +2 | tr -d ' :\n')"
mcp-publisher login dns --domain whisperr.net --private-key "${PRIVATE_KEY}"
cd registry && mcp-publisher publish
```

## 5. VS Code / GitHub MCP Registry

The VS Code `@mcp` gallery reads the GitHub MCP Registry. Step 4 is
done, so check https://github.com/mcp for the current self-publish process. If it is
still manual, **George** emails `partnerships@github.com` with the registry
name `net.whisperr/whisperr`. The install link in the README works without a
listing.

## 6. Catalogs that need no review

Step 4 is done. Smithery (https://smithery.ai/new, paste the server URL);
check whether mcp.so, Glama and PulseMCP already import the registry entry.

## Release checklist (each version)

1. Raise `version` in `.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`
   and `plugin.json` (CI fails when they differ).
2. `python3 scripts/validate.py --require-schema` and
   `claude plugin validate --strict .claude-plugin/plugin.json`.
3. Merge to `main`, tag `vX.Y.Z`, push the tag. The release workflow builds
   the OpenAI ZIP and attaches it to the GitHub release.
4. Upload the ZIP to the OpenAI portal (skills/metadata changes only).
   Claude and Cursor pick up the commit from GitHub.
