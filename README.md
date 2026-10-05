# Whisperr agent kit

![Whisperr](assets/icon.png)

Install [Whisperr](https://whisperr.net) with the coding agent you already
use. Whisperr finds the users who are about to churn and sends the right
message at the right time. This kit connects your agent to the Whisperr MCP
server and gives it three skills:

| Skill | What it does |
|---|---|
| `whisperr-install` | Detects your stack, installs the Whisperr SDK at the latest version, adds init, identify/reset, push tokens, push-open tracking and RevenueCat linking with Whisperr's privacy rules, wires your event plan, builds before and after (no new errors), then waits until real events arrive. |
| `whisperr-insights` | Answers retention questions ("how many users are at risk, and why?") from your live Whisperr data. Changes become proposals that a person approves in the dashboard. |
| `whisperr-keep-in-sync` | Checks every code change that touches tracked events, so a refactor does not silently stop an event. |

Supported stacks: Swift/iOS, React Native/Expo, Flutter, web (React,
Next.js, any JS app) and Node. Python, PHP and .NET follow the
[docs](https://docs.whisperr.net/).

MCP server: `https://mcp.whisperr.net/mcp` (Streamable HTTP, OAuth 2.1).
The first tool call opens a browser sign-in. You pick one Whisperr app and
approve scopes: `data:read`, `install:write` (owners and admins) and
`changes:propose`. You need a Whisperr account.

## Install

### Claude Code

In a Claude Code session:

```text
/plugin marketplace add WhisperrAI/whisperr-agent-kit
/plugin install whisperr@whisperr
```

Or from your shell:

```bash
claude plugin marketplace add WhisperrAI/whisperr-agent-kit
claude plugin install whisperr@whisperr
```

Restart the session, run `/mcp`, select `whisperr` and sign in. Then ask:
"Install Whisperr in this app."

MCP server only (no skills):
`claude mcp add --transport http whisperr https://mcp.whisperr.net/mcp`

### Cursor

[![Add Whisperr MCP server to Cursor](https://cursor.com/deeplink/mcp-install-dark.svg)](https://cursor.com/install-mcp?name=whisperr&config=eyJ1cmwiOiJodHRwczovL21jcC53aGlzcGVyci5uZXQvbWNwIn0%3D)

Deeplink (paste into a browser):
`cursor://anysphere.cursor-deeplink/mcp/install?name=whisperr&config=eyJ1cmwiOiJodHRwczovL21jcC53aGlzcGVyci5uZXQvbWNwIn0=`

For the skills and the rule, copy [`rules/whisperr.mdc`](rules/whisperr.mdc)
to `.cursor/rules/whisperr.mdc` and the [`skills/`](skills/) folders to
`.cursor/skills/`. The full plugin (MCP server, skills and rule) is also
available from the Cursor Marketplace after review.

### VS Code (GitHub Copilot agent mode)

[![Install in VS Code](https://img.shields.io/badge/VS_Code-Install_Whisperr-0098FF)](https://vscode.dev/redirect/mcp/install?name=whisperr&config=%7B%22type%22%3A%22http%22%2C%22url%22%3A%22https%3A%2F%2Fmcp.whisperr.net%2Fmcp%22%7D)

Or from your shell:

```bash
code --add-mcp '{"name":"whisperr","type":"http","url":"https://mcp.whisperr.net/mcp"}'
```

### Codex and ChatGPT

Codex CLI, plugin with skills:

```bash
codex plugin marketplace add WhisperrAI/whisperr-agent-kit
codex plugin add whisperr@whisperr
```

MCP server only:

```bash
codex mcp add whisperr --url https://mcp.whisperr.net/mcp
codex mcp login whisperr
```

ChatGPT and the Codex app: install **Whisperr** from the plugin directory
after it is listed. Until then, add `https://mcp.whisperr.net/mcp` as a
custom MCP connection in ChatGPT developer mode.

### Windsurf (Devin Desktop)

Devin Local agent:

```bash
devin mcp add whisperr https://mcp.whisperr.net/mcp
```

Legacy Cascade agent: add this to `mcp_config.json`
(`~/.config/devin/mcp_config.json`; older Windsurf installs use
`~/.codeium/windsurf/mcp_config.json`):

```json
{
  "mcpServers": {
    "whisperr": { "serverUrl": "https://mcp.whisperr.net/mcp" }
  }
}
```

Copy [`snippets/windsurf-whisperr.md`](snippets/windsurf-whisperr.md) to
`.windsurf/rules/whisperr.md`.

### Lovable, Bolt, Replit, Rork and other app builders

Use the copy-prompt fallback: [`snippets/copy-prompt.md`](snippets/copy-prompt.md).
Paste your publishable key and event list into the prompt, then paste the
prompt into the tool. Replit also accepts a custom remote MCP server URL.

### Any other MCP client

```json
{
  "mcpServers": {
    "whisperr": { "type": "http", "url": "https://mcp.whisperr.net/mcp" }
  }
}
```

## Always-loaded rules for your repository

Agents follow short, always-loaded rules better than on-demand skills. Paste
the block that fits your agent into your repository:

| Agent | File in your repo | Source |
|---|---|---|
| Codex, Cursor, Copilot, most agents | `AGENTS.md` | [`snippets/AGENTS.md`](snippets/AGENTS.md) |
| Claude Code | `CLAUDE.md` | [`snippets/CLAUDE.md`](snippets/CLAUDE.md) |
| Cursor | `.cursor/rules/whisperr.mdc` | [`rules/whisperr.mdc`](rules/whisperr.mdc) |
| Windsurf | `.windsurf/rules/whisperr.md` | [`snippets/windsurf-whisperr.md`](snippets/windsurf-whisperr.md) |

Replace the `<…>` placeholders with your SDK package, version, init file and
key variable. The `whisperr-install` skill offers to do this for you.

## What this kit runs, sends and stores

- The kit contains only text: manifests, skills, rules and images. It runs no
  code on your machine and installs no packages by itself. Your agent runs
  the commands that the skills describe (package install, build, analyze), in
  your terminal, with your approval settings.
- The only network destination the kit configures is the Whisperr MCP server
  `https://mcp.whisperr.net/mcp`, operated by Whisperr. Your agent sends it
  tool arguments: event codes, file paths and short code lines for event
  selection, build results, and your questions about your data.
- Whisperr tools never return delivery addresses (email, phone, push
  tokens), API keys or secrets. Changes to your workspace are proposals until
  a member approves them in the Whisperr dashboard.
- The skills tell your agent to send `first_name` as the only name trait and
  to send email and phone only as consented channels.

Privacy policy: https://whisperr.net/privacy/ · Terms:
https://whisperr.net/terms/ · Security: https://whisperr.net/security/

## Repository layout

| Path | For |
|---|---|
| `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.mcp.json` | Claude Code plugin and marketplace |
| `.cursor-plugin/plugin.json`, `rules/` | Cursor plugin |
| `plugin.json`, `mcp.json` | Portable [Agent Plugins](https://agent-plugins.org) package, with the OpenAI listing under `extensions.com.openai` (ChatGPT and Codex) |
| `.agents/plugins/marketplace.json` | Codex repo marketplace |
| `skills/` | The three skills (shared by every agent) |
| `snippets/` | `AGENTS.md`, `CLAUDE.md` and Windsurf blocks, copy-prompt fallback |
| `registry/server.json` | Official MCP Registry entry `net.whisperr/whisperr` |
| `scripts/validate.py` | Manifest, schema and skill checks (CI) |
| `scripts/build-openai-zip.sh` | Builds `dist/whisperr-openai-plugin.zip` for the OpenAI plugin portal |
| `PUBLISHING.md` | Submission steps for each directory |

## Develop

```bash
pip install jsonschema pyyaml
python3 scripts/validate.py --require-schema
claude plugin validate --strict .claude-plugin/plugin.json
./scripts/build-openai-zip.sh
```

Raise `version` in `.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`
and `plugin.json` together for every release, then tag `vX.Y.Z`. The release
workflow attaches the OpenAI ZIP to the GitHub release.

## Formats used (checked 2026-10-05)

- Claude Code plugins, marketplaces, `.mcp.json` and skills:
  https://code.claude.com/docs/en/plugins-reference ·
  https://code.claude.com/docs/en/plugins/marketplace-reference ·
  https://code.claude.com/docs/en/plugins/publish ·
  https://code.claude.com/docs/en/skills
- Claude plugin directory: https://claude.com/docs/plugins/submit ·
  https://claude.com/docs/plugins/pre-submission-checklist
- Cursor plugins and MCP install links:
  https://cursor.com/docs/reference/plugins ·
  https://cursor.com/docs/mcp/install-links
- VS Code MCP install URLs:
  https://code.visualstudio.com/api/extension-guides/ai/mcp
- OpenAI plugins (ChatGPT and Codex):
  https://developers.openai.com/plugins/build/plugins ·
  https://developers.openai.com/plugins/deploy/submission ·
  https://learn.chatgpt.com/docs/extend/mcp
- Agent Plugins schemas: https://agent-plugins.org/schemas/1.0.0/plugin.schema.json
- Windsurf / Devin Desktop MCP: https://docs.devin.ai/desktop/cascade/mcp
- Official MCP Registry:
  https://github.com/modelcontextprotocol/registry/blob/main/docs/modelcontextprotocol-io/remote-servers.mdx ·
  https://github.com/modelcontextprotocol/registry/blob/main/docs/modelcontextprotocol-io/authentication.mdx

## License

MIT. See [LICENSE](LICENSE). Issues and questions:
https://github.com/WhisperrAI/whisperr-agent-kit/issues
