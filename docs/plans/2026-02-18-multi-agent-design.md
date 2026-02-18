# Multi-Agent Architecture Design

> Approved: 2026-02-18

## Goal

Split the existing single-agent OpenClaw setup into 2 isolated agents:
- **daily** — general-purpose assistant (migrate existing config)
- **home** — smart home controller via Apple Shortcuts MCP

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Home model | `zai/glm-4-flash` | Cheaper/faster; smart home commands are simple |
| Existing workspace | Copy to workspace-daily | Preserve original as backup |
| HomeBot DM policy | pairing | Same security level as daily bot |
| HomeBot personality | Plan draft (concise controller) | KISS — no unnecessary personality |
| Approach | Full plan execution (Plan A) | Research is thorough, execute as-is |

## Config Changes (openclaw.template.json)

### agents section

```json
{
  "agents": {
    "defaults": {
      "maxConcurrent": 4,
      "subagents": { "maxConcurrent": 8 },
      "compaction": { "mode": "safeguard" }
    },
    "list": [
      {
        "id": "daily",
        "default": true,
        "workspace": "~/.openclaw/workspace-daily",
        "model": "zai/glm-4.7",
        "tools": { "profile": "full" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "home",
        "workspace": "~/.openclaw/workspace-home",
        "model": "zai/glm-4-flash",
        "identity": { "name": "HomeBot", "theme": "smart home controller" },
        "tools": {
          "profile": "messaging",
          "allow": ["shortcuts"],
          "deny": ["group:fs", "group:runtime", "browser", "group:web"]
        },
        "sandbox": { "mode": "all", "scope": "agent" }
      }
    ]
  }
}
```

### channels.telegram

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "accounts": {
        "default": {
          "_botToken_comment": "Existing bot token via env var"
        },
        "homebot": {
          "_botToken_comment": "Set via TELEGRAM_BOT_TOKEN_HOME env var",
          "dmPolicy": "pairing"
        }
      }
    }
  }
}
```

### bindings

```json
{
  "bindings": [
    {
      "agentId": "daily",
      "match": { "channel": "telegram", "accountId": "default" }
    },
    {
      "agentId": "home",
      "match": { "channel": "telegram", "accountId": "homebot" }
    }
  ]
}
```

### models (in agents.defaults)

```json
{
  "models": {
    "zai/glm-4.7": { "alias": "GLM" },
    "zai/glm-4-flash": { "alias": "GLM-Flash" }
  }
}
```

## Workspace Files

### workspace-daily

Copy entire `~/.openclaw/workspace/` to `~/.openclaw/workspace-daily/` (no modifications).

### workspace-home (new)

**SOUL.md:**
```
You are HomeBot, a smart home controller.
- Respond in Traditional Chinese
- Be precise and brief — no unnecessary chatter
- When asked to control a device, use the apple-shortcuts MCP tool
- Always confirm the action after execution
- If the requested shortcut doesn't exist, list available shortcuts
- Never attempt to access files, browse the web, or run shell commands
```

**AGENTS.md:**
```
# Operating Rules
- Only respond to smart home related requests
- For non-smart-home requests, politely redirect: "This is the smart home channel. Please use the daily bot for other requests."
- Use run_shortcut tool to control devices
- Use list_shortcuts tool if unsure what's available
```

**USER.md:**
```
# Smart Home Setup
- Platform: Apple HomeKit (controlled via macOS Shortcuts app)
- Available rooms and devices: [TODO: fill in after creating shortcuts]
- Available shortcuts: [TODO: fill in after creating shortcuts in Shortcuts app]
```

## Migration Steps

1. Backup current config: `./scripts/backup.sh`
2. Create workspace directories
3. Copy existing workspace to workspace-daily
4. Create workspace-home files (SOUL.md, AGENTS.md, USER.md)
5. Update `openclaw.template.json` with multi-agent config
6. Update `.env.example` with `TELEGRAM_BOT_TOKEN_HOME`
7. Run `./scripts/apply.sh`
8. Run `openclaw security audit`
9. Restart daemon (launchctl unload/load)
10. Test daily bot — should work as before
11. Test home bot — should respond to smart home commands

## Security

- Home agent: sandbox all, scope agent
- Home agent: deny fs, runtime, browser, web
- Home agent: allow only messaging + shortcuts
- HomeBot token via env var (never in git)
- DM policy: pairing (requires pairing code)

## Rollback

- Original workspace preserved at `~/.openclaw/workspace/`
- Pre-change backup via `./scripts/backup.sh`
- Git revert template + `./scripts/apply.sh` to restore
