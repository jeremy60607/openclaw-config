#!/usr/bin/env bash
set -euo pipefail

# ===========================================
# OpenClaw Clean Uninstall Script
# Stops daemon, removes config, uninstalls
# ===========================================

OPENCLAW_HOME="$HOME/.openclaw"
PLIST="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"

echo "=========================================="
echo " OpenClaw Clean Uninstall"
echo "=========================================="
echo ""
echo "This will:"
echo "  1. Stop the gateway daemon"
echo "  2. Remove launchd agent"
echo "  3. Uninstall openclaw npm package"
echo "  4. Remove ~/.openclaw/ directory"
echo ""
echo "WARNING: All session data, agent memory, and configs will be deleted."
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# --- Step 1: Stop daemon ---
echo ""
echo "[1/4] Stopping gateway daemon..."

if launchctl list | grep -q "ai.openclaw.gateway" 2>/dev/null; then
  launchctl unload "$PLIST" 2>/dev/null && echo "  Daemon stopped." || echo "  Could not unload (may already be stopped)."
else
  echo "  No running daemon found."
fi

# --- Step 2: Remove launchd plist ---
echo "[2/4] Removing launchd agent..."

if [ -f "$PLIST" ]; then
  rm "$PLIST"
  echo "  Removed: $PLIST"
else
  echo "  No plist found."
fi

# --- Step 3: Uninstall npm package ---
echo "[3/4] Uninstalling openclaw..."

if command -v openclaw &>/dev/null; then
  npm uninstall -g openclaw
  echo "  Uninstalled."
else
  echo "  openclaw not found in PATH."
fi

# --- Step 4: Remove config directory ---
echo "[4/4] Removing ~/.openclaw/..."

if [ -d "$OPENCLAW_HOME" ]; then
  rm -rf "$OPENCLAW_HOME"
  echo "  Removed: $OPENCLAW_HOME"
else
  echo "  Directory not found."
fi

echo ""
echo "=========================================="
echo " Clean uninstall complete."
echo "=========================================="
echo ""
echo "To reinstall, run: ./scripts/setup.sh"
