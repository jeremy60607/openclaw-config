# Installed Skills

> Update this file whenever you install/remove skills.
> Run `openclaw skill check <name>` to verify any skill.

## Currently Installed

### Core (npm global)
| Skill | Install Command | Purpose |
|-------|----------------|---------|
| clawhub | `npm i -g clawhub` | Skill marketplace — search, install, update skills |
| mcporter | `npm i -g mcporter` | MCP server management — list, configure, call MCP tools |

### Smart Home (ClawHub)
| Skill | Install Command | Purpose |
|-------|----------------|---------|
| homekit | `clawhub install homekit --dir ~/.openclaw/skills` | Control Apple HomeKit devices (lights, switches, outlets, thermostats) |

> Python deps for homekit: `pip3 install "HAP-python[QRCode]" aiohomekit`

## Recommended Skills to Install

Browse: https://github.com/VoltAgent/awesome-openclaw-skills

### Productivity
```bash
# Example:
# openclaw skill install task-manager
```

### Development
```bash
# openclaw skill install code-review
```

### Security
```bash
# openclaw skill install security-scan
```

## High-Risk Skills (use with caution)

These skills have elevated system access. Enable sandbox when using them:

- `exec` - shell command execution
- `browser` - browser automation
- `web_fetch` - arbitrary URL fetching
- `web_search` - web search

## Skill Priority

Workspace (`<project>/skills/`) > User (`~/.openclaw/skills/`) > Built-in

## Useful Commands

```bash
# Install a skill
openclaw skill install <name>

# Install from ClawHub
npx clawhub@latest install <skill-slug>

# Verify a skill
openclaw skill check <name>

# List installed skills
ls ~/.openclaw/skills/
```
