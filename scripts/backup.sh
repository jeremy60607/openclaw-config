#!/usr/bin/env bash
set -euo pipefail

# ===========================================
# OpenClaw Backup Script
# Backs up config (without secrets) to project
# ===========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_HOME="$HOME/.openclaw"
BACKUP_DIR="$PROJECT_DIR/backups/$(date +%Y%m%d-%H%M%S)"

echo "=========================================="
echo " OpenClaw Backup"
echo "=========================================="
echo ""

if [ ! -d "$OPENCLAW_HOME" ]; then
  echo "ERROR: ~/.openclaw/ not found. Nothing to back up."
  exit 1
fi

mkdir -p "$BACKUP_DIR"

# --- Backup config (strip secrets) ---
echo "[1/4] Backing up config (secrets redacted)..."

if [ -f "$OPENCLAW_HOME/openclaw.json" ] && command -v node &>/dev/null; then
  node -e "
    const fs = require('fs');
    const cfg = JSON.parse(fs.readFileSync('$OPENCLAW_HOME/openclaw.json', 'utf8'));

    // Redact secrets
    if (cfg.gateway?.auth?.token) cfg.gateway.auth.token = '<REDACTED>';
    if (cfg.auth?.profiles) {
      for (const key of Object.keys(cfg.auth.profiles)) {
        const p = cfg.auth.profiles[key];
        if (p.apiKey) p.apiKey = '<REDACTED>';
        if (p.token) p.token = '<REDACTED>';
      }
    }

    // Remove meta timestamps
    delete cfg.meta;
    delete cfg.wizard;

    fs.writeFileSync('$BACKUP_DIR/openclaw.sanitized.json', JSON.stringify(cfg, null, 2));
  "
  echo "  Saved: $BACKUP_DIR/openclaw.sanitized.json"
else
  echo "  WARNING: Could not sanitize config. Skipping."
fi

# --- Backup skills list ---
echo "[2/4] Backing up installed skills..."

SKILLS_DIR="$OPENCLAW_HOME/skills"
if [ -d "$SKILLS_DIR" ] && [ "$(ls -A "$SKILLS_DIR" 2>/dev/null)" ]; then
  ls -1 "$SKILLS_DIR" > "$BACKUP_DIR/installed-skills.txt"
  echo "  Saved: $BACKUP_DIR/installed-skills.txt"
else
  echo "  No user skills installed."
  echo "(none)" > "$BACKUP_DIR/installed-skills.txt"
fi

WORKSPACE_SKILLS="$OPENCLAW_HOME/workspace/skills"
if [ -d "$WORKSPACE_SKILLS" ] && [ "$(ls -A "$WORKSPACE_SKILLS" 2>/dev/null)" ]; then
  ls -1 "$WORKSPACE_SKILLS" > "$BACKUP_DIR/workspace-skills.txt"
  echo "  Saved: $BACKUP_DIR/workspace-skills.txt"
fi

# --- Backup version info ---
echo "[3/4] Saving version info..."

{
  echo "date: $(date -Iseconds)"
  echo "openclaw: $(openclaw --version 2>/dev/null || echo 'not installed')"
  echo "node: $(node -v)"
  echo "npm: $(npm -v)"
  echo "os: $(uname -mrs)"
} > "$BACKUP_DIR/version-info.txt"
echo "  Saved: $BACKUP_DIR/version-info.txt"

# --- Backup launchd plist ---
echo "[4/4] Backing up daemon config..."

PLIST="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
if [ -f "$PLIST" ]; then
  # Strip tokens from plist
  sed 's|<string>[a-f0-9]\{20,\}</string>|<string>REDACTED</string>|g' "$PLIST" > "$BACKUP_DIR/gateway.plist.sanitized"
  echo "  Saved: $BACKUP_DIR/gateway.plist.sanitized"
else
  echo "  No launchd plist found."
fi

echo ""
echo "=========================================="
echo " Backup complete: $BACKUP_DIR"
echo "=========================================="
echo ""
echo "Files:"
ls -la "$BACKUP_DIR/"
