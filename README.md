# OpenClaw Local Setup Manager

Reproducible configuration for local OpenClaw installation.

## Quick Start (Fresh Machine)

```bash
# 1. Install Node >= 22
brew install node

# 2. Copy env.example to .env and fill in API keys
cp env.example .env
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
├── env.example                   # Environment variables template
├── scripts/
│   ├── setup.sh                  # Fresh install script
│   ├── clean.sh                  # Clean uninstall script
│   └── backup.sh                 # Backup current config (redacts secrets)
├── skills/
│   └── skills-list.md            # Installed skills registry
├── mcp/
│   └── mcp-config.md             # MCP server configurations
├── security/
│   └── hardening-checklist.md    # Security hardening checklist
└── backups/                      # Auto-created by backup.sh
```

## Workflows

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
