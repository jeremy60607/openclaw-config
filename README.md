# OpenClaw Local Setup Manager

Reproducible configuration for local OpenClaw installation.

## Quick Start (Fresh Machine)

```bash
# 1. Install Node >= 22
brew install node

# 2. Copy .env.example to .env and fill in API keys
cp .env.example .env
# edit .env with your keys

# 3. Run setup
chmod +x scripts/*.sh
./scripts/setup.sh
```

## Project Structure

```
.
├── README.md                     # This file
├── openclaw.template.json        # Config template (no secrets)
├── .env.example                  # Environment variables template
├── scripts/
│   ├── setup.sh                  # Fresh install script
│   ├── apply.sh                  # Apply template to live config (GitOps core)
│   ├── clean.sh                  # Clean uninstall script
│   ├── sync.sh                   # Reverse sync: live config → template
│   ├── detect-drift.sh           # Compare live config vs template (JSON report)
│   └── backup.sh                 # Backup current config (redacts secrets)
├── skills/
│   └── skills-list.md            # Installed skills registry
├── mcp/
│   └── mcp-config.md             # MCP server configurations
├── security/
│   └── hardening-checklist.md    # Security hardening checklist
└── backups/                      # Auto-created by backup.sh
```

## GitOps Workflow

All config changes follow: **edit template -> commit -> apply -> verify**

```bash
# 1. Edit openclaw.template.json
# 2. Commit the change
# 3. Apply to live config (preserves secrets)
./scripts/apply.sh
# 4. Verify
openclaw security audit
```

## Workflows

### Apply Config Changes (Forward: repo → live)
```bash
./scripts/apply.sh
```

### Reverse Sync (Live → repo)
When config changes are made outside the repo (e.g. via Telegram, `openclaw onboard`, or manual edits):
```bash
# Preview what would change
./scripts/sync.sh --dry-run

# Apply reverse sync (updates template + skills list)
./scripts/sync.sh

# Review and commit
git diff
git commit -m "chore: sync live config changes to template"
```

### Detect Config Drift
```bash
# Returns JSON report, exit 0 = no drift, exit 1 = drift
./scripts/detect-drift.sh
```

### Backup Current Setup
```bash
./scripts/backup.sh
```

### Clean Uninstall
```bash
./scripts/clean.sh
```

### Reinstall
```bash
./scripts/setup.sh
```

### Update OpenClaw
```bash
./scripts/backup.sh
npm install -g openclaw@latest
openclaw doctor
```

## Key Paths

| Path | Purpose |
|------|---------|
| `~/.openclaw/openclaw.json` | Main config |
| `~/.openclaw/skills/` | User-level skills |
| `~/.openclaw/logs/` | Gateway logs |
| `~/.openclaw/agents/` | Agent data & sessions |
| `~/Library/LaunchAgents/ai.openclaw.gateway.plist` | macOS daemon |

## Security

See [security/hardening-checklist.md](security/hardening-checklist.md) for the full checklist.

Key rules:
- **Never** commit `.env` or API keys to git
- Gateway token = admin password, treat accordingly
- Run `openclaw security audit --deep` after any config change

## Useful Links

- GitHub: https://github.com/openclaw/openclaw
- Docs: https://docs.openclaw.ai
- Releases: https://github.com/openclaw/openclaw/releases
- Skills: https://github.com/VoltAgent/awesome-openclaw-skills
- Security: https://docs.openclaw.ai/gateway/security
