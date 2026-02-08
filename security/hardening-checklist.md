# OpenClaw Security Hardening Checklist

> Run `openclaw security audit --deep` after setup to verify.

## macOS Device Security

- [x] FileVault (full disk encryption) enabled
- [ ] Find My Mac enabled (verify in System Settings → Apple ID → iCloud → Find My Mac)
- [x] Screen lock enabled (300s delay — consider reducing to 60s or less)
- [ ] macOS Firewall enabled (System Settings → Network → Firewall)
- [ ] Firmware password set (Intel Macs) or Activation Lock enabled (Apple Silicon)
- [ ] Automatic macOS updates enabled

## Initial Setup

- [x] Gateway binds to `loopback` (127.0.0.1), not 0.0.0.0
- [x] Gateway auth mode set to `token`
- [ ] API keys stored in env vars, NOT in openclaw.json
- [x] File permissions: `chmod 700 ~/.openclaw && chmod 600 ~/.openclaw/openclaw.json`
- [ ] Never run as root; use dedicated user account

## DM & Channel Security

- [ ] DM policy set to `pairing` or `allowlist` (never `open`)
- [ ] Group mentionGating enabled (`mentionGating: true`)
- [ ] Sender allowlists reviewed and up to date

## Network

- [ ] Port 18789 not exposed to public internet
- [ ] Use VPN or Tailscale for remote access
- [ ] Firewall rules configured (UFW or macOS firewall)
- [ ] mDNS broadcast set to `minimal` or `off`

## Skills & Tools

- [ ] High-risk skills (exec, browser, web_fetch) sandboxed
- [ ] Only install skills from trusted sources (check awesome-openclaw-skills curated list)
- [ ] Run `openclaw skill check <name>` before enabling new skills
- [ ] Tool allowlists configured per agent

## Secrets Management

- [ ] Gateway token not committed to git
- [ ] API keys rotated quarterly
- [ ] Secrets stored in password manager (1Password, Bitwarden, etc.)
- [ ] `.env` file in `.gitignore`

## Monitoring & Maintenance

- [x] Command logger hook enabled
- [ ] Logs reviewed periodically (`~/.openclaw/logs/`)
- [x] `openclaw security audit` run monthly
- [x] Config drift detection cron job (every 6h via `detect-drift.sh`)
- [ ] `npm audit` run on openclaw dependencies
- [ ] OpenClaw updated to latest stable version

## Prompt Injection Defense

- [ ] Untrusted content handled by read-only agent first
- [ ] Browser automation limited to allowlisted domains
- [ ] Dedicated browser profiles (not personal)
- [ ] Human approval required for high-risk actions

## Incident Response

If compromise suspected:
1. Stop gateway: `launchctl unload ~/Library/LaunchAgents/ai.openclaw.gateway.plist`
2. Rotate all tokens and API keys
3. Review logs: `~/.openclaw/logs/`
4. Review session transcripts: `~/.openclaw/agents/`
5. Run `openclaw security audit --deep`

## References

- https://docs.openclaw.ai/gateway/security
- https://www.hostinger.com/tutorials/openclaw-security
- https://guardz.com/blog/openclaw-hardening-for-msps/
