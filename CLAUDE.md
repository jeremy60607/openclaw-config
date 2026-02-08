# OpenClaw Local Setup Manager

This project manages a local OpenClaw installation using GitOps principles.
All configuration changes flow through version-controlled templates, never directly edit the live config.

## GitOps Workflow (MUST follow)

```
Edit template → git commit → ./scripts/apply.sh → verify → done
```

1. **Modify** `openclaw.template.json` (the single source of truth for non-secret config)
2. **Commit** the change to git with conventional commit message
3. **Apply** via `./scripts/apply.sh` — merges template into live `~/.openclaw/openclaw.json`, preserving secrets
4. **Verify** with `openclaw security audit` and test via Web UI (`http://localhost:18789`)
5. **Backup** with `./scripts/backup.sh` if the change is significant

**NEVER** edit `~/.openclaw/openclaw.json` directly for non-secret settings. Always go through the template.

## Secrets Handling

- Secrets (API keys, tokens) are NEVER stored in git
- They live in `~/.openclaw/openclaw.json` (injected by onboard wizard) or env vars
- `.env.example` documents which env vars are needed — copy to `.env` for local use
- `apply.sh` automatically preserves secrets from the live config during merge
- The template uses `_*_comment` fields as placeholders for secret fields

## Key Paths

| Path | What | In Git? |
|------|------|---------|
| `openclaw.template.json` | Config source of truth | Yes |
| `.env.example` | Env var documentation | Yes |
| `~/.openclaw/openclaw.json` | Live config (has secrets) | No |
| `~/.openclaw/skills/` | Installed skills | No |
| `~/.openclaw/logs/` | Gateway logs | No |
| `~/Library/LaunchAgents/ai.openclaw.gateway.plist` | macOS daemon | No |

## Scripts

| Script | Purpose | When |
|--------|---------|------|
| `scripts/setup.sh` | Fresh install on new machine | First time only |
| `scripts/apply.sh` | Apply template to live config | After every template change |
| `scripts/backup.sh` | Backup live config (secrets redacted) | Before risky changes |
| `scripts/clean.sh` | Complete uninstall | When removing OpenClaw |

## Common Tasks for Claude

### Changing a config setting
1. Read `openclaw.template.json`
2. Edit the relevant field in the template
3. Run `./scripts/apply.sh`
4. Run `openclaw security audit`
5. Commit the template change

### Installing a skill
1. Run `openclaw skill install <name>`
2. Run `openclaw skill check <name>` to verify
3. Update `skills/skills-list.md` with the skill name and install command
4. Commit the skills-list change

### Adding an MCP server
1. Add the MCP config to `openclaw.template.json` under `mcpServers`
2. Document it in `mcp/mcp-config.md`
3. Run `./scripts/apply.sh`
4. Commit both files

### Changing AI provider or model
1. Update `agents.defaults.model.primary` in `openclaw.template.json`
2. Update `agents.defaults.models` with the new model alias
3. Update `auth.profiles` if the provider changes
4. Run `./scripts/apply.sh`
5. Set the new API key in env vars or via `openclaw onboard`
6. Commit the template change

### Updating OpenClaw version
1. Run `./scripts/backup.sh`
2. Run `npm install -g openclaw@latest`
3. Run `openclaw doctor`
4. Run `openclaw security audit`
5. If config schema changed, update `openclaw.template.json` accordingly
6. Commit any template changes

### Adding a channel (Telegram, Discord, etc.)
1. Run `openclaw onboard` (re-run just the channel step)
2. Update `openclaw.template.json` with the non-secret channel config
3. Document the channel setup in `mcp/mcp-config.md` or a new doc
4. Run `./scripts/apply.sh`
5. Commit

### Transferring to a new machine
1. Clone this repo on the new machine
2. Copy `.env.example` to `.env`, fill in API keys
3. Run `./scripts/setup.sh` (installs OpenClaw, runs onboard wizard)
4. Run `./scripts/apply.sh` (applies all template settings)
5. Re-install skills listed in `skills/skills-list.md`

## Current Setup

- **OpenClaw version**: 2026.2.6-3
- **Provider**: ZAI / GLM-4.7
- **Gateway**: localhost:18789, loopback, token auth
- **Channel**: Telegram
- **Daemon**: launchd (auto-start on login)
- **Web UI**: http://localhost:18789

## Rules

- Language: respond in Traditional Chinese; code/commits/docs in English
- Conventional Commits format
- Do NOT `git push` without explicit user request
- Do NOT modify live config directly — always use template + apply
- Do NOT commit secrets — check `git diff --cached` before every commit
- Run `openclaw security audit` after any config change
- Update `skills/skills-list.md` when installing/removing skills
- Update `mcp/mcp-config.md` when adding/removing MCP servers
- Update `security/hardening-checklist.md` when security posture changes
- Consult https://docs.openclaw.ai for latest API/config changes (OpenClaw is actively developed)

## Security Baseline

- Gateway: loopback only, token auth required
- File permissions: `chmod 700 ~/.openclaw`, `chmod 600 openclaw.json`
- DM policy: pairing or allowlist (never open)
- High-risk skills: must be sandboxed
- Run `openclaw security audit --deep` monthly
- See `security/hardening-checklist.md` for full checklist
