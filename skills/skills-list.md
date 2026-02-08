# Installed Skills

> Update this file whenever you install/remove skills.
> Run `openclaw skill check <name>` to verify any skill.

## Currently Installed

_None yet - fresh install._

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
