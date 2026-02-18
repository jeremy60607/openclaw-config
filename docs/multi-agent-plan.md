# Multi-Agent Architecture Plan

> This document captures research and decisions from the initial brainstorming session.
> Use it as context for the implementation session.

## Goal

Set up OpenClaw multi-agent with isolated context, system prompt, skills, and memory per agent.
Control smart home devices via Apple Shortcuts MCP without conflicting with existing HomeKit pairings.

## Architecture Decision

```
Telegram
│
├── @DailyBot (existing bot) ──→ 「daily」agent
│   • General purpose: daily tasks, work, research, conversation
│   • Full tool access
│   • Current config migrated here
│
└── @HomeBot (new bot, already created) ──→ 「smart-home」agent
    • Smart home control only
    • Minimal tools: shortcuts + messaging only
    • Sandboxed for security
    • Lightweight model (smart home commands are simple)
```

## What Each Agent Needs

### daily agent
- **id**: `daily` (default agent)
- **workspace**: `~/.openclaw/workspace-daily`
- **model**: `zai/glm-4.7` (current setup, migrate existing config)
- **tools**: `profile: full`
- **sandbox**: off
- **SOUL.md**: General-purpose assistant personality
- **MEMORY.md**: Migrate from current workspace if any

### smart-home agent
- **id**: `home`
- **workspace**: `~/.openclaw/workspace-home`
- **model**: TBD (consider a cheaper/faster model — commands are simple)
- **tools**: `profile: messaging`, allow only `shortcuts`
- **tools deny**: `group:fs`, `group:runtime`, `browser`, `group:web`
- **sandbox**: `mode: all, scope: agent`
- **SOUL.md**: Focused on HomeKit control, precise and brief responses
- **USER.md**: List of rooms, devices, and available shortcuts

## Key Config Structure

### agents section (in openclaw.template.json)
```json5
{
  "agents": {
    "defaults": {
      "maxConcurrent": 4,
      // ... existing defaults
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
        "model": "TBD",
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

### bindings section
```json5
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

### channels.telegram section
```json5
{
  "channels": {
    "telegram": {
      "accounts": {
        "default": {
          // existing bot token (env var)
        },
        "homebot": {
          "botToken": "env:TELEGRAM_BOT_TOKEN_HOME"
          // configure dmPolicy, groupPolicy as needed
        }
      }
    }
  }
}
```

## MCP Server (Already Configured)

Apple Shortcuts MCP is installed via mcporter (home scope):
```bash
mcporter list  # should show apple-shortcuts (2 tools: list_shortcuts, run_shortcut)
```

The home agent needs access to this MCP. Verify mcporter tools are visible to the home agent's tool allowlist.

## Workspace Files to Create

### ~/.openclaw/workspace-home/SOUL.md
```markdown
You are HomeBot, a smart home controller.
- Respond in Traditional Chinese
- Be precise and brief — no unnecessary chatter
- When asked to control a device, use the apple-shortcuts MCP tool
- Always confirm the action after execution
- If the requested shortcut doesn't exist, list available shortcuts
- Never attempt to access files, browse the web, or run shell commands
```

### ~/.openclaw/workspace-home/USER.md
```markdown
# Smart Home Setup
- Platform: Apple HomeKit (controlled via macOS Shortcuts app)
- Available rooms and devices: [TODO: fill in after creating shortcuts]
- Available shortcuts: [TODO: fill in after creating shortcuts in Shortcuts app]
```

### ~/.openclaw/workspace-home/AGENTS.md
```markdown
# Operating Rules
- Only respond to smart home related requests
- For non-smart-home requests, politely redirect: "This is the smart home channel. Please use the daily bot for other requests."
- Use run_shortcut tool to control devices
- Use list_shortcuts tool if unsure what's available
```

## Migration Checklist

- [ ] Backup current config: `./scripts/backup.sh`
- [ ] Create workspace directories for both agents
- [ ] Write SOUL.md, AGENTS.md, USER.md for each workspace
- [ ] Migrate existing workspace content to workspace-daily if needed
- [ ] Update openclaw.template.json with multi-agent config
- [ ] Add TELEGRAM_BOT_TOKEN_HOME to .env
- [ ] Run `./scripts/apply.sh`
- [ ] Run `openclaw security audit`
- [ ] Restart daemon (launchctl unload/load)
- [ ] Test daily bot — should work as before
- [ ] Test home bot — should respond to smart home commands
- [ ] Create Apple Shortcuts for HomeKit devices
- [ ] Test: message HomeBot "列出所有捷徑" → should call list_shortcuts
- [ ] Test: message HomeBot "開客廳燈" → should call run_shortcut
- [ ] Update skills/skills-list.md if needed
- [ ] Update mcp/mcp-config.md if needed
- [ ] Commit all changes

## Important Notes from Research

1. **Never share agentDir** between agents — causes auth/session collision
2. **Agent-to-agent** communication is off by default — enable only if needed
3. **Per-topic agent routing** has limitations (Issue #1615) — can override systemPrompt per topic but cannot change agentId
4. **Main thread bottleneck** (Issue #16055) — multiple bots share main FIFO queue (4 concurrent)
5. **mcpServers key does NOT go in openclaw.json** — use `mcporter config add` instead
6. **Shortcuts must be created manually** in Shortcuts.app — no API exists to create them programmatically
7. HomeKit control via Shortcuts avoids the pairing conflict issue (HAP-python homekit skill creates a separate pairing)

## Apple Shortcuts to Create (in Shortcuts.app)

Create these shortcuts manually. Name them clearly for AI recognition:
- [TODO: List your HomeKit devices and the shortcuts you need]
- Example naming convention: "開客廳燈", "關客廳燈", "冷氣設26度"

## References

- [Multi-Agent Routing Docs](https://docs.openclaw.ai/concepts/multi-agent)
- [System Prompt Docs](https://docs.openclaw.ai/concepts/system-prompt)
- [Telegram Channel Docs](https://docs.openclaw.ai/channels/telegram)
- [Apple Shortcuts MCP](https://github.com/recursechat/mcp-server-apple-shortcuts) (301 stars, Apache-2.0)
- [macOS Automator MCP](https://github.com/steipete/macos-automator-mcp) (641 stars, MIT) — not installed, available if needed later
