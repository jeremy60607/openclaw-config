#!/usr/bin/env bash
set -euo pipefail

# ===========================================
# OpenClaw Setup Script
# Installs OpenClaw and applies configuration
# ===========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OPENCLAW_HOME="$HOME/.openclaw"

echo "=========================================="
echo " OpenClaw Setup Script"
echo "=========================================="
echo ""

# --- Pre-flight checks ---
echo "[1/6] Checking prerequisites..."

if ! command -v node &>/dev/null; then
  echo "ERROR: Node.js not found. Install Node >= 22 first."
  echo "  brew install node"
  exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 22 ]; then
  echo "ERROR: Node >= 22 required. Current: $(node -v)"
  echo "  brew install node"
  exit 1
fi

echo "  Node $(node -v) OK"

# --- Check for .env ---
echo ""
echo "[2/6] Checking environment variables..."

if [ -f "$PROJECT_DIR/.env" ]; then
  echo "  Loading .env file..."
  set -a
  source "$PROJECT_DIR/.env"
  set +a
elif [ -f "$PROJECT_DIR/env.local" ]; then
  echo "  Loading env.local file..."
  set -a
  source "$PROJECT_DIR/env.local"
  set +a
else
  echo "  WARNING: No .env file found."
  echo "  Copy env.example to .env and fill in your API keys before running this script."
  echo ""
  read -p "  Continue without .env? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# --- Install OpenClaw ---
echo ""
echo "[3/6] Installing OpenClaw (latest stable)..."

if command -v openclaw &>/dev/null; then
  CURRENT_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
  echo "  OpenClaw already installed: v${CURRENT_VERSION}"
  read -p "  Reinstall/upgrade? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    npm install -g openclaw@latest
  fi
else
  npm install -g openclaw@latest
fi

echo "  OpenClaw $(openclaw --version) installed."

# --- Run onboarding wizard ---
echo ""
echo "[4/6] Running onboarding wizard..."
echo "  This will set up authentication, channels, and generate gateway token."
echo ""

openclaw onboard --install-daemon

# --- Apply config template ---
echo ""
echo "[5/6] Applying configuration template..."

if [ -f "$OPENCLAW_HOME/openclaw.json" ]; then
  echo "  Backing up current config to openclaw.json.pre-template"
  cp "$OPENCLAW_HOME/openclaw.json" "$OPENCLAW_HOME/openclaw.json.pre-template"
fi

echo "  NOTE: The onboarding wizard has created a config."
echo "  Review openclaw.template.json and merge settings manually if needed:"
echo "    $PROJECT_DIR/openclaw.template.json"
echo ""

# --- Security hardening ---
echo ""
echo "[6/6] Applying security defaults..."

chmod 700 "$OPENCLAW_HOME" 2>/dev/null || true
chmod 600 "$OPENCLAW_HOME/openclaw.json" 2>/dev/null || true

echo "  File permissions set (700/600)."
echo ""

# --- Verify ---
echo "=========================================="
echo " Verification"
echo "=========================================="

echo ""
echo "OpenClaw version: $(openclaw --version)"
echo "Config location:  $OPENCLAW_HOME/openclaw.json"
echo "Logs:             $OPENCLAW_HOME/logs/"
echo ""

echo "Running security audit..."
openclaw security audit 2>/dev/null || echo "  (security audit not available in this version, run manually)"

echo ""
echo "=========================================="
echo " Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Review security checklist: $PROJECT_DIR/security/hardening-checklist.md"
echo "  2. Install skills:            openclaw skill install <name>"
echo "  3. Start gateway:             openclaw gateway --port 18789 --verbose"
echo "  4. Open web UI:               http://localhost:18789"
echo "  5. Update skills list:        $PROJECT_DIR/skills/skills-list.md"
echo ""
