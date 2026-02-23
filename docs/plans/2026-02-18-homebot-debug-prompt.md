# HomeBot MCP Tool Debug Session

## Context

Multi-agent migration is 90% complete. Daily bot works fine. HomeBot (smart home controller) can receive Telegram messages and respond, but **cannot access MCP tools** (`list_shortcuts`, `run_shortcut` from `mcp-server-apple-shortcuts`).

## Current State

- OpenClaw 2026.2.6-3, multi-agent config with `daily` and `home` agents
- HomeBot Telegram: `@jeremy_smart_home_bot` (token injected in live config)
- MCP server `apple-shortcuts` is healthy: `mcporter list` shows 2 tools, 0.3s
- `mcporter call apple-shortcuts.list_shortcuts` works fine from CLI
- HomeBot responds to messages but says "無法存取 shortcuts" instead of calling tools
- The LLM (zai/glm-4.7-flash) knows the tools exist (from SOUL.md) but can't invoke them

## The Problem

Error in `~/.openclaw/logs/gateway.err.log`:
```
[tools] agents.home.tools.allow allowlist contains unknown entries (apple-shortcuts).
These entries won't match any tool unless the plugin is enabled.
```

We changed `alsoAllow` from `["apple-shortcuts"]` to `["list_shortcuts", "run_shortcut"]` but haven't confirmed if this resolves the error. The latest commit (299d9c6) has this change.

## What to Debug

1. **Check if the `alsoAllow: ["list_shortcuts", "run_shortcut"]` fix works** — restart daemon, send a message to HomeBot, check `gateway.err.log` for new tool errors
2. **If still failing**: MCP tools from mcporter may not be directly accessible as agent tools. Need to find the correct way to expose mcporter MCP tools to specific agents in OpenClaw multi-agent config
3. **Reference docs**: `/opt/homebrew/lib/node_modules/openclaw/docs/multi-agent-sandbox-tools.md` and `/opt/homebrew/lib/node_modules/openclaw/docs/plugins/agent-tools.md`
4. **Alternative approach**: If per-agent MCP binding isn't supported, consider removing the `deny` list entirely and relying on SOUL.md behavioral restrictions only

## Key Files

| File | Purpose |
|------|---------|
| `openclaw.template.json` | Template with agent config (lines 84-88 = home tools) |
| `~/.openclaw/openclaw.json` | Live config (has secrets) |
| `~/.openclaw/workspace-home/SOUL.md` | HomeBot persona + tool instructions |
| `~/.openclaw/workspace-home/AGENTS.md` | HomeBot operating rules |
| `~/.mcporter/mcporter.json` | MCP server config |
| `~/.openclaw/logs/gateway.err.log` | Error logs |
| `~/.openclaw/logs/gateway.log` | Activity logs |

## Commands

```bash
# Check MCP health
mcporter list --schema

# Test MCP tool directly
mcporter call apple-shortcuts.list_shortcuts

# Apply template and restart
./scripts/apply.sh
launchctl unload ~/Library/LaunchAgents/ai.openclaw.gateway.plist
sleep 2
launchctl load ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# Check for tool errors
grep "tools.*unknown\|tools.*allow" ~/.openclaw/logs/gateway.err.log | tail -5

# Check channel status
openclaw channels status
```

## What's Already Done (don't redo)

- Backup, workspace creation, script updates, template config — all committed
- dmPolicy set to `allowlist` + `allowFrom: ["*"]` in live config (template still says `pairing`, sync later)
- SOUL.md and AGENTS.md updated with strong MCP tool instructions
- `mcp-server-apple-shortcuts` installed globally at `/opt/homebrew/bin/`
- mcporter config updated to use global binary (not npx)
