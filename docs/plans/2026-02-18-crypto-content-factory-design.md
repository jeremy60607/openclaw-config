# Crypto Content Factory — Design Document

> Date: 2026-02-18
> Status: Implemented (2026-02-23)

## Goal

Automate daily crypto news collection, market data analysis, and Instagram-ready content production using OpenClaw's multi-agent architecture.

## User Context

- Instagram: @cryptopaii (crypto trading signals + market analysis + news)
- Target: Traditional Chinese speaking crypto traders
- Delivery: Telegram DM → user reviews → manually posts to IG
- Frequency: Daily morning briefing (07:30)

## Architecture

### Agent

A new `crypto` agent under the existing multi-agent setup:

```
Telegram Bots
├── @DailyBot  → "daily" agent (existing, general purpose)
├── @HomeBot   → "home" agent (planned, smart home)
└── @CryptoBot → "crypto" agent (NEW, content factory) ⭐
```

### Subagent Pipeline

The crypto agent orchestrates 3 subagent roles (not separate agents):

```
@CryptoBot → "crypto" agent
  ├── [collector] News/data collection
  │   └── Tools: brave-search, rss, firecrawl, coingecko
  │
  ├── [writer] Content production
  │   └── Tools: GLM-4.7 (text generation)
  │
  └── [designer] Image generation
      └── Tools: mcp-image (Gemini) or imagegen-mcp (DALL-E)
```

### Daily Workflow

```
[cron 07:30]
    │
    ▼
[1. collector]
    ├── RSS: CoinDesk, The Block, PANews, CoinTelegraph
    ├── Brave News Search: "crypto" + "bitcoin" + "ethereum" (24h)
    ├── Firecrawl: deep-read top 3-5 articles
    └── CoinGecko: BTC/ETH/SOL 24h + trending + top gainers
    │
    ▼
[2. writer]
    ├── Market Overview (prices, 24h change, Fear & Greed)
    ├── News Digest (5-8 key stories, 2-3 sentences each)
    ├── IG Post ×2 (caption + hashtags)
    └── Trading Insight (optional, only if clear signal)
    │
    ▼
[3. designer]
    └── Generate IG images (1080×1080)
    │
    ▼
[Telegram DM to user]
    ├── 📊 Market Overview
    ├── 📰 News Digest
    ├── 📱 IG Post #1 + image
    ├── 📱 IG Post #2 + image
    └── 💡 Trading Insight (optional)
```

## MCP Servers Required

| MCP | Package | API Key | Cost |
|-----|---------|---------|------|
| Brave Search | `@modelcontextprotocol/server-brave-search` | `BRAVE_API_KEY` | Free 2000/mo |
| Firecrawl | `firecrawl-mcp` | `FIRECRAWL_API_KEY` | Free 500 credits/mo |
| RSS | `rss-mcp` | None | Free |
| CoinGecko | `@coingecko/coingecko-mcp` | `COINGECKO_API_KEY` (optional) | Free Demo |
| Image Gen | `mcp-image` | `GEMINI_API_KEY` | Free tier |

### Installation (via mcporter)

```bash
mcporter config add brave-search \
  --command "npx" --arg "-y" --arg "@modelcontextprotocol/server-brave-search" \
  --env "BRAVE_API_KEY=<key>" --scope home

mcporter config add firecrawl \
  --command "npx" --arg "-y" --arg "firecrawl-mcp" \
  --env "FIRECRAWL_API_KEY=<key>" --scope home

mcporter config add rss \
  --command "npx" --arg "-y" --arg "rss-mcp" \
  --scope home

mcporter config add coingecko \
  --command "npx" --arg "-y" --arg "@coingecko/coingecko-mcp" \
  --scope home

mcporter config add mcp-image \
  --command "npx" --arg "-y" --arg "mcp-image" \
  --env "GEMINI_API_KEY=<key>" --scope home
```

## OpenClaw Configuration

### Agent (in openclaw.template.json)

```json
{
  "id": "crypto",
  "workspace": "~/.openclaw/workspace-crypto",
  "model": "zai/glm-4.7",
  "identity": {
    "name": "CryptoBot",
    "theme": "crypto content factory"
  },
  "tools": {
    "profile": "full",
    "allow": ["brave-search", "firecrawl", "rss", "coingecko", "mcp-image"],
    "deny": ["group:fs"]
  },
  "subagents": {
    "maxConcurrent": 3
  },
  "sandbox": {
    "mode": "tools",
    "scope": "agent"
  }
}
```

### Telegram Binding

```json
{
  "bindings": [
    { "agentId": "daily",  "match": { "channel": "telegram", "accountId": "default" } },
    { "agentId": "home",   "match": { "channel": "telegram", "accountId": "homebot" } },
    { "agentId": "crypto", "match": { "channel": "telegram", "accountId": "cryptobot" } }
  ]
}
```

### Environment Variables

```bash
TELEGRAM_BOT_TOKEN_CRYPTO=<from @BotFather>
BRAVE_API_KEY=<from brave.com/search/api>
FIRECRAWL_API_KEY=<from firecrawl.dev>
GEMINI_API_KEY=<from aistudio.google.com>
COINGECKO_API_KEY=<from coingecko.com/api>  # optional, free Demo
```

## Workspace Files

### ~/.openclaw/workspace-crypto/SOUL.md

```markdown
You are CryptoBot, a professional crypto content factory.

## Role
- Collect, analyze, and produce high-quality crypto content for an Instagram audience
- Target audience: Traditional Chinese speaking crypto traders and investors
- Tone: Professional but accessible, data-driven, avoid hype

## Daily Workflow
When triggered by the morning schedule:
1. Collect — Use RSS, Brave Search, and CoinGecko to gather data
2. Analyze — Filter noise, identify the 5-8 most important stories
3. Write — Produce summaries and IG-ready content
4. Design — Generate matching visuals

## Output Format
Always deliver in this structure:
1. 📊 Market Overview (BTC, ETH, SOL prices, 24h change, Fear & Greed)
2. 📰 News Digest (5-8 key stories, 2-3 sentences each)
3. 📱 IG Post #1 (caption + hashtags + image)
4. 📱 IG Post #2 (caption + hashtags + image)
5. 💡 Trading Insight (optional, only if clear signal exists)

## Content Rules
- Language: Traditional Chinese (繁體中文)
- Never give direct financial advice
- Use phrases like "值得關注", "數據顯示", "市場動態"
- IG captions: 150-300 chars, punchy, with 10-15 relevant hashtags
- Images: 1080×1080, clean design, data-focused
```

### ~/.openclaw/workspace-crypto/USER.md

```markdown
# Content Strategy
- Platform: Instagram (@cryptopaii)
- Niche: Crypto trading signals + market analysis + news
- Goal: Build community, drive traffic to Telegram group
- Post frequency: 1-2 posts/day

# RSS Feeds
- CoinDesk: https://www.coindesk.com/arc/outboundfeeds/rss/
- The Block: https://www.theblock.co/rss.xml
- PANews: https://www.panewslab.com/rss/zh/index.xml
- CoinTelegraph: https://cointelegraph.com/rss

# Tracked Coins
- Tier 1: BTC, ETH, SOL
- Tier 2: [TODO: Add your watchlist]

# IG Style Guide
- Color scheme: [TODO: Define brand colors]
- Font style: [TODO: Define preferences]
- Hashtags pool: #crypto #比特幣 #以太坊 #加密貨幣 #幣圈 #交易 #投資
```

## Scheduling

```bash
# crontab entry
30 7 * * * openclaw run --agent crypto --message "執行每日內容生產流程"
```

## Implementation Checklist

- [ ] Create @CryptoBot via @BotFather
- [ ] Get API keys: Brave, Firecrawl, Gemini, CoinGecko (optional)
- [ ] Install MCP servers via mcporter (5 servers)
- [ ] Create workspace directory: ~/.openclaw/workspace-crypto/
- [ ] Write SOUL.md, USER.md, AGENTS.md
- [ ] Update openclaw.template.json with crypto agent config
- [ ] Add TELEGRAM_BOT_TOKEN_CRYPTO to .env
- [ ] Run ./scripts/apply.sh
- [ ] Run openclaw security audit
- [ ] Restart daemon
- [ ] Test: message @CryptoBot manually → verify all MCP tools work
- [ ] Test: trigger daily workflow manually
- [ ] Set up cron job
- [ ] Fine-tune prompts based on output quality
- [ ] Update skills/skills-list.md
- [ ] Update mcp/mcp-config.md
- [ ] Commit all changes

## Notes

- RSS is the backbone for consistent news coverage; Brave Search supplements for breaking news
- CoinGecko free Demo tier: 30 calls/min, 10,000 monthly credits — sufficient for daily use
- Firecrawl free tier: 500 credits/month — use selectively for deep reads only
- Image generation via Gemini is free tier; DALL-E is an alternative if quality differs
- The subagent approach (vs. separate agents) avoids needing 3 bot tokens and simplifies data flow
- Content should NEVER include direct financial advice to avoid regulatory issues
