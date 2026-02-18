# Multi-Agent Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split OpenClaw into 2 isolated agents (daily + home) with separate workspaces, models, and Telegram bots.

**Architecture:** Each agent gets its own workspace directory with SOUL.md/AGENTS.md/USER.md, bound to a separate Telegram bot via the bindings config. The home agent is sandboxed with minimal tools (messaging + Apple Shortcuts MCP only).

**Tech Stack:** OpenClaw (Node.js), launchd daemon, Telegram Bot API, Apple Shortcuts MCP

**Design doc:** `docs/plans/2026-02-18-multi-agent-design.md`

---

## Task 1: Backup Current Config

**Files:**
- Run: `scripts/backup.sh`

**Step 1: Run backup script**

Run: `./scripts/backup.sh`
Expected: Backup created in `backups/YYYYMMDD-HHMMSS/` with sanitized config, skills list, version info, and plist.

**Step 2: Verify backup exists**

Run: `ls -la backups/ | tail -1`
Expected: A new timestamped directory.

**Step 3: Commit backup**

```bash
git add backups/
git commit -m "chore: backup config before multi-agent migration"
```

---

## Task 2: Create Workspace Directories and Copy Daily Workspace

**Files:**
- Create: `~/.openclaw/workspace-daily/` (copy from `~/.openclaw/workspace/`)
- Create: `~/.openclaw/workspace-home/`

**Step 1: Create directories**

```bash
mkdir -p ~/.openclaw/workspace-daily
mkdir -p ~/.openclaw/workspace-home
```

**Step 2: Copy existing workspace to workspace-daily**

```bash
cp -a ~/.openclaw/workspace/. ~/.openclaw/workspace-daily/
```

Note: Using `cp -a` to preserve all attributes and hidden files. The trailing `.` copies contents, not the directory itself.

**Step 3: Verify copy**

Run: `diff <(ls -la ~/.openclaw/workspace/) <(ls -la ~/.openclaw/workspace-daily/)`
Expected: Identical file listings (timestamps may differ).

---

## Task 3: Create Home Workspace Files

**Files:**
- Create: `~/.openclaw/workspace-home/SOUL.md`
- Create: `~/.openclaw/workspace-home/AGENTS.md`
- Create: `~/.openclaw/workspace-home/USER.md`

**Step 1: Write SOUL.md**

Create `~/.openclaw/workspace-home/SOUL.md` with:
```markdown
# SOUL.md - Who You Are

You are HomeBot, a smart home controller.

## Core Behavior
- Respond in Traditional Chinese
- Be precise and brief — no unnecessary chatter
- When asked to control a device, use the apple-shortcuts MCP tool
- Always confirm the action after execution
- If the requested shortcut doesn't exist, list available shortcuts
- Never attempt to access files, browse the web, or run shell commands

## Continuity

Each session, you wake up fresh. Read your workspace files for context.
```

**Step 2: Write AGENTS.md**

Create `~/.openclaw/workspace-home/AGENTS.md` with:
```markdown
# AGENTS.md - Operating Rules

## Scope
- Only respond to smart home related requests
- For non-smart-home requests, politely redirect: "這是智慧家電頻道，請使用日常 bot 處理其他需求。"

## Tools
- Use `run_shortcut` tool to control devices
- Use `list_shortcuts` tool if unsure what's available
- Do NOT attempt to use any other tools

## Safety
- Never run shell commands
- Never access the filesystem
- Never browse the web
- Always confirm actions after execution
```

**Step 3: Write USER.md**

Create `~/.openclaw/workspace-home/USER.md` with:
```markdown
# USER.md - Smart Home Setup

## Platform
- Apple HomeKit (controlled via macOS Shortcuts app)

## Available Rooms and Devices
[TODO: Fill in after creating shortcuts in Shortcuts.app]

## Available Shortcuts
[TODO: Fill in after creating shortcuts in Shortcuts.app]

Example naming convention:
- "開客廳燈" / "關客廳燈"
- "冷氣設26度"
- "全部關燈"
```

**Step 4: Verify workspace structure**

Run: `ls -la ~/.openclaw/workspace-home/`
Expected: SOUL.md, AGENTS.md, USER.md all present.

---

## Task 4: Update Scripts for Multi-Account Telegram

The apply.sh, sync.sh, and backup.sh scripts hardcode single-account telegram token handling (`channels.telegram.botToken`). They must be updated to support the multi-account structure (`channels.telegram.accounts.*.botToken`).

**Files:**
- Modify: `scripts/apply.sh` (lines 53-94, the Node.js secret preservation logic)
- Modify: `scripts/sync.sh` (lines 51-111, the Node.js sanitization logic)
- Modify: `scripts/backup.sh` (lines 29-54, the Node.js redaction logic)

### Step 1: Update apply.sh secret preservation

In `scripts/apply.sh`, replace the secret extraction and restoration logic (the `node -e` block, lines 47-123) with updated code that handles both single-account and multi-account telegram structures:

```javascript
// Extract secrets from live config to preserve
const secrets = {
  gatewayToken: live.gateway?.auth?.token,
  // Support both single-account and multi-account telegram
  telegramBotToken: live.channels?.telegram?.botToken,
  telegramAccounts: {},
  authProfiles: live.auth?.profiles,
  meta: live.meta,
  wizard: live.wizard,
};

// Extract per-account telegram tokens
if (live.channels?.telegram?.accounts) {
  for (const [name, acct] of Object.entries(live.channels.telegram.accounts)) {
    if (acct.botToken) {
      secrets.telegramAccounts[name] = acct.botToken;
    }
  }
}
```

And update the restoration section:

```javascript
// Restore secrets (template should never contain these)
if (secrets.gatewayToken) {
  merged.gateway = merged.gateway || {};
  merged.gateway.auth = merged.gateway.auth || {};
  merged.gateway.auth.token = secrets.gatewayToken;
}
// Restore single-account telegram token (legacy)
if (secrets.telegramBotToken) {
  merged.channels = merged.channels || {};
  merged.channels.telegram = merged.channels.telegram || {};
  merged.channels.telegram.botToken = secrets.telegramBotToken;
}
// Restore multi-account telegram tokens
for (const [name, token] of Object.entries(secrets.telegramAccounts)) {
  if (merged.channels?.telegram?.accounts?.[name]) {
    merged.channels.telegram.accounts[name].botToken = token;
  }
}
if (secrets.authProfiles) {
  merged.auth = merged.auth || {};
  merged.auth.profiles = secrets.authProfiles;
}
if (secrets.meta) merged.meta = secrets.meta;
if (secrets.wizard) merged.wizard = secrets.wizard;
```

### Step 2: Update sync.sh secret stripping

In `scripts/sync.sh`, update the sanitization node block (lines 60-68) to also strip multi-account tokens:

```javascript
// Remove secrets: telegram bot token (single-account legacy)
if (sanitized.channels?.telegram?.botToken) {
  delete sanitized.channels.telegram.botToken;
  sanitized.channels.telegram._botToken_comment = 'Set via OPENCLAW_TELEGRAM_BOT_TOKEN env var or paste during onboard wizard';
}

// Remove secrets: telegram account tokens (multi-account)
if (sanitized.channels?.telegram?.accounts) {
  for (const [name, acct] of Object.entries(sanitized.channels.telegram.accounts)) {
    if (acct.botToken) {
      delete acct.botToken;
      acct._botToken_comment = `Set via env var`;
    }
  }
}
```

Also update the dry-run preview block (lines 130-135) with the same logic.

### Step 3: Update backup.sh secret redaction

In `scripts/backup.sh`, update the redaction node block (lines 35-36) to also redact multi-account tokens:

```javascript
// Redact single-account telegram token
if (cfg.channels?.telegram?.botToken) cfg.channels.telegram.botToken = '<REDACTED>';

// Redact multi-account telegram tokens
if (cfg.channels?.telegram?.accounts) {
  for (const [name, acct] of Object.entries(cfg.channels.telegram.accounts)) {
    if (acct.botToken) acct.botToken = '<REDACTED>';
  }
}
```

### Step 4: Verify scripts parse correctly

Run:
```bash
bash -n scripts/apply.sh && echo "apply.sh OK"
bash -n scripts/sync.sh && echo "sync.sh OK"
bash -n scripts/backup.sh && echo "backup.sh OK"
```
Expected: All three print OK (syntax valid).

### Step 5: Commit script updates

```bash
git add scripts/apply.sh scripts/sync.sh scripts/backup.sh
git commit -m "fix: update scripts to handle multi-account telegram tokens"
```

---

## Task 5: Update openclaw.template.json

**Files:**
- Modify: `openclaw.template.json`

**Step 1: Update agents section**

Replace the current `agents` block with the multi-agent config. Keep existing `defaults` fields, add `list` array.

The `agents` section should become:
```json
"agents": {
  "defaults": {
    "maxConcurrent": 4,
    "subagents": {
      "maxConcurrent": 8
    },
    "compaction": {
      "mode": "safeguard"
    },
    "models": {
      "zai/glm-4.7": {
        "alias": "GLM"
      },
      "zai/glm-4-flash": {
        "alias": "GLM-Flash"
      }
    },
    "model": {
      "primary": "zai/glm-4.7"
    }
  },
  "list": [
    {
      "id": "daily",
      "default": true,
      "workspace": "~/.openclaw/workspace-daily",
      "model": "zai/glm-4.7",
      "tools": {
        "profile": "full"
      },
      "sandbox": {
        "mode": "off"
      }
    },
    {
      "id": "home",
      "workspace": "~/.openclaw/workspace-home",
      "model": "zai/glm-4-flash",
      "identity": {
        "name": "HomeBot",
        "theme": "smart home controller"
      },
      "tools": {
        "profile": "messaging",
        "allow": ["shortcuts"],
        "deny": ["group:fs", "group:runtime", "browser", "group:web"]
      },
      "sandbox": {
        "mode": "all",
        "scope": "agent"
      }
    }
  ]
}
```

Note: Remove the old `"workspace": "/Users/agent/.openclaw/workspace"` from defaults — each agent now specifies its own.

**Step 2: Update channels.telegram section**

Replace the current `channels` block with multi-account structure:
```json
"channels": {
  "telegram": {
    "enabled": true,
    "accounts": {
      "default": {
        "_botToken_comment": "Set via OPENCLAW_TELEGRAM_BOT_TOKEN env var or paste during onboard wizard"
      },
      "homebot": {
        "_botToken_comment": "Set via TELEGRAM_BOT_TOKEN_HOME env var",
        "dmPolicy": "pairing"
      }
    }
  }
}
```

**Step 3: Add bindings section**

Add a new top-level `bindings` key:
```json
"bindings": [
  {
    "agentId": "daily",
    "match": {
      "channel": "telegram",
      "accountId": "default"
    }
  },
  {
    "agentId": "home",
    "match": {
      "channel": "telegram",
      "accountId": "homebot"
    }
  }
]
```

**Step 4: Verify JSON is valid**

Run: `node -e "JSON.parse(require('fs').readFileSync('openclaw.template.json','utf8')); console.log('Valid JSON')"`
Expected: "Valid JSON"

**Step 5: Commit template changes**

```bash
git add openclaw.template.json
git commit -m "feat: add multi-agent config with daily and home agents"
```

---

## Task 6: Update .env.example and Docs

**Files:**
- Modify: `.env.example`
- Modify: `mcp/mcp-config.md`

**Step 1: Update .env.example**

Add the HomeBot token env var after the existing telegram section:

```
# --- Telegram ---
# OPENCLAW_TELEGRAM_BOT_TOKEN=   (existing daily bot)
TELEGRAM_BOT_TOKEN_HOME=
```

**Step 2: Update mcp/mcp-config.md**

Add a note under the Apple Shortcuts section about which agent uses it:

```markdown
- **Used by**: `home` agent (smart home controller)
- **Agent access**: The home agent's tool allowlist includes `shortcuts`
```

**Step 3: Commit doc updates**

```bash
git add .env.example mcp/mcp-config.md
git commit -m "docs: add HomeBot token to env example, update MCP docs"
```

---

## Task 7: Apply Config and Verify

**Files:**
- Run: `scripts/apply.sh`

**Step 1: Set HomeBot token env var**

The user must set `TELEGRAM_BOT_TOKEN_HOME` in their `.env` or environment before applying. Prompt user to provide the token.

Run: `echo "TELEGRAM_BOT_TOKEN_HOME=<token>" >> ~/.openclaw/.env` (or however OpenClaw reads env vars)

**Step 2: Apply template to live config**

Run: `./scripts/apply.sh`
Expected: "Apply complete" with no errors. Should show backup path and successful merge.

**Step 3: Verify live config has multi-agent structure**

Run: `node -e "const c=JSON.parse(require('fs').readFileSync('$HOME/.openclaw/openclaw.json','utf8')); console.log('agents:', c.agents?.list?.length, 'bindings:', c.bindings?.length)"`
Expected: `agents: 2 bindings: 2`

**Step 4: Verify no secrets in template**

Run: `grep -r "botToken\|apiKey\|token" openclaw.template.json | grep -v comment | grep -v _comment`
Expected: No output (no real secrets in template).

---

## Task 8: Security Audit and Restart

**Step 1: Run security audit**

Run: `openclaw security audit`
Expected: Pass with no critical issues. Note any warnings about the new agent config.

**Step 2: Restart the daemon**

```bash
launchctl unload ~/Library/LaunchAgents/ai.openclaw.gateway.plist
sleep 2
launchctl load ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

**Step 3: Verify daemon is running**

Run: `launchctl list | grep openclaw`
Expected: `ai.openclaw.gateway` with exit status 0.

**Step 4: Check Web UI**

Open `http://localhost:18789` in browser — should show the gateway is healthy.

---

## Task 9: Test Both Bots

**Step 1: Test daily bot**

Send a message to the existing @DailyBot on Telegram. It should respond as before, using the daily agent's workspace and personality.

**Step 2: Test home bot — pairing**

Send `/start` or any message to @HomeBot on Telegram. It should prompt for pairing code (since dmPolicy is pairing).

**Step 3: Complete pairing and test**

After pairing, send "列出所有捷徑" to HomeBot.
Expected: HomeBot calls `list_shortcuts` MCP tool and returns the list of available Apple Shortcuts.

**Step 4: Test home bot refuses non-smart-home requests**

Send "幫我寫一封 email" to HomeBot.
Expected: HomeBot redirects to daily bot: "這是智慧家電頻道，請使用日常 bot 處理其他需求。"

---

## Task 10: Final Commit and Cleanup

**Step 1: Verify git status**

Run: `git status`
Expected: All changes committed from previous tasks. No untracked files (except possibly backups/).

**Step 2: If any uncommitted changes, commit them**

```bash
git add -A
git commit -m "chore: finalize multi-agent migration"
```

**Step 3: Update security checklist if needed**

Check `security/hardening-checklist.md` — update with notes about the home agent's sandbox and tool restrictions.

**Step 4: Final verification summary**

Run:
```bash
echo "=== Migration Complete ==="
echo "Daily workspace:" && ls ~/.openclaw/workspace-daily/SOUL.md
echo "Home workspace:" && ls ~/.openclaw/workspace-home/SOUL.md
echo "Daemon:" && launchctl list | grep openclaw
echo "Template agents:" && node -e "const c=JSON.parse(require('fs').readFileSync('openclaw.template.json','utf8')); console.log(c.agents.list.map(a=>a.id))"
```
Expected: Both workspaces exist, daemon running, template lists `["daily", "home"]`.
