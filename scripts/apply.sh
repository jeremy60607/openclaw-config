#!/usr/bin/env bash
set -euo pipefail

# ===========================================
# OpenClaw Apply Script (GitOps core)
# Merges template into live config,
# preserving secrets from the running config.
# ===========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_HOME="$HOME/.openclaw"
LIVE_CONFIG="$OPENCLAW_HOME/openclaw.json"
TEMPLATE="$PROJECT_DIR/openclaw.template.json"

echo "=========================================="
echo " OpenClaw Apply (GitOps)"
echo "=========================================="
echo ""

# --- Pre-flight ---
if [ ! -f "$TEMPLATE" ]; then
  echo "ERROR: Template not found: $TEMPLATE"
  exit 1
fi

if [ ! -f "$LIVE_CONFIG" ]; then
  echo "ERROR: Live config not found: $LIVE_CONFIG"
  echo "Run 'openclaw onboard --install-daemon' first."
  exit 1
fi

if ! command -v node &>/dev/null; then
  echo "ERROR: Node.js required for JSON merge."
  exit 1
fi

# --- Backup current ---
echo "[1/4] Backing up current config..."
BACKUP="$LIVE_CONFIG.pre-apply.$(date +%Y%m%d-%H%M%S)"
cp "$LIVE_CONFIG" "$BACKUP"
echo "  Saved: $BACKUP"

# --- Merge ---
echo "[2/4] Merging template into live config (preserving secrets)..."

node -e "
const fs = require('fs');

const live = JSON.parse(fs.readFileSync('$LIVE_CONFIG', 'utf8'));
const template = JSON.parse(fs.readFileSync('$TEMPLATE', 'utf8'));

// Extract secrets from live config to preserve
const secrets = {
  gatewayToken: live.gateway?.auth?.token,
  telegramBotToken: live.channels?.telegram?.botToken,
  authProfiles: live.auth?.profiles,
  meta: live.meta,
  wizard: live.wizard,
};

// Deep merge: template values override, but we keep live-only keys
function deepMerge(target, source) {
  const result = { ...target };
  for (const key of Object.keys(source)) {
    if (
      source[key] &&
      typeof source[key] === 'object' &&
      !Array.isArray(source[key]) &&
      target[key] &&
      typeof target[key] === 'object' &&
      !Array.isArray(target[key])
    ) {
      result[key] = deepMerge(target[key], source[key]);
    } else {
      result[key] = source[key];
    }
  }
  return result;
}

// Start from live, merge template on top
let merged = deepMerge(live, template);

// Restore secrets (template should never contain these)
if (secrets.gatewayToken) {
  merged.gateway = merged.gateway || {};
  merged.gateway.auth = merged.gateway.auth || {};
  merged.gateway.auth.token = secrets.gatewayToken;
}
if (secrets.telegramBotToken) {
  merged.channels = merged.channels || {};
  merged.channels.telegram = merged.channels.telegram || {};
  merged.channels.telegram.botToken = secrets.telegramBotToken;
}
if (secrets.authProfiles) {
  merged.auth = merged.auth || {};
  merged.auth.profiles = secrets.authProfiles;
}
if (secrets.meta) merged.meta = secrets.meta;
if (secrets.wizard) merged.wizard = secrets.wizard;

// Remove template-only comment fields
function removeComments(obj) {
  if (!obj || typeof obj !== 'object') return obj;
  const result = Array.isArray(obj) ? [...obj] : { ...obj };
  for (const key of Object.keys(result)) {
    if (key.startsWith('_') && key.endsWith('_comment')) {
      delete result[key];
    } else if (typeof result[key] === 'object') {
      result[key] = removeComments(result[key]);
    }
  }
  return result;
}

merged = removeComments(merged);

// Remove \$schema (not a real config key)
delete merged['\$schema'];

fs.writeFileSync('$LIVE_CONFIG', JSON.stringify(merged, null, 2) + '\n');
console.log('  Merged successfully.');
"

# --- Permissions ---
echo "[3/4] Setting file permissions..."
chmod 600 "$LIVE_CONFIG"
echo "  chmod 600 applied."

# --- Verify ---
echo "[4/4] Verifying config..."

# Check JSON is valid
node -e "JSON.parse(require('fs').readFileSync('$LIVE_CONFIG', 'utf8')); console.log('  JSON valid.');"

# Check gateway is running
if launchctl list | grep -q "ai.openclaw.gateway" 2>/dev/null; then
  echo "  Gateway daemon is running."
  echo ""
  echo "  To reload config, restart the daemon:"
  echo "    launchctl unload ~/Library/LaunchAgents/ai.openclaw.gateway.plist"
  echo "    launchctl load   ~/Library/LaunchAgents/ai.openclaw.gateway.plist"
else
  echo "  WARNING: Gateway daemon not running."
fi

echo ""
echo "=========================================="
echo " Apply complete."
echo "=========================================="
echo ""
echo "Changes applied from: $TEMPLATE"
echo "Backup saved to:      $BACKUP"
echo ""
echo "Run 'openclaw security audit' to verify."
