# MCP Server Configuration

> MCP (Model Context Protocol) servers extend OpenClaw with external tool access.
> Add MCP server configs to the `mcpServers` section in `openclaw.json`.

## Currently Configured

### Apple Shortcuts (run macOS Shortcuts)
- **Repo**: https://github.com/recursechat/mcp-server-apple-shortcuts
- **Stars**: 301 | **License**: Apache-2.0
- **Tools**: list shortcuts, run shortcut by name (with optional input)
- **Use case**: Execute pre-built HomeKit shortcuts to control smart home devices without creating a separate HomeKit pairing
- **Used by**: `home` agent (smart home controller)
- **Agent access**: The home agent's tool allowlist includes `shortcuts`
```json
"apple-shortcuts": {
  "command": "npx",
  "args": ["-y", "mcp-server-apple-shortcuts"]
}
```

### Brave Search (web/news search)
- **Package**: `@modelcontextprotocol/server-brave-search`
- **Tools**: `brave_web_search`, `brave_local_search`
- **API Key**: `BRAVE_API_KEY` (free 2000 queries/mo — https://brave.com/search/api/)
- **Used by**: `crypto` agent (news collection)
```json
"brave-search": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-brave-search"],
  "env": { "BRAVE_API_KEY": "<key>" }
}
```

### Firecrawl (web scraping)
- **Package**: `firecrawl-mcp`
- **Tools**: `firecrawl_scrape`, `firecrawl_search`, `firecrawl_map`, `firecrawl_crawl`, + 8 more
- **API Key**: `FIRECRAWL_API_KEY` (free 500 credits/mo — https://firecrawl.dev)
- **Used by**: `crypto` agent (deep article reading)
```json
"firecrawl": {
  "command": "npx",
  "args": ["-y", "firecrawl-mcp"],
  "env": { "FIRECRAWL_API_KEY": "<key>" }
}
```

### RSS Reader (RSS/Atom feeds)
- **Package**: `rss-reader-mcp`
- **Tools**: `fetch_feed_entries`, `fetch_article_content`
- **API Key**: None
- **Used by**: `crypto` agent (daily news feeds)
```json
"rss": {
  "command": "npx",
  "args": ["-y", "rss-reader-mcp"]
}
```

### Gemini Image Generation
- **Package**: `mcp-image`
- **Tools**: `generate_image`
- **API Key**: `GEMINI_API_KEY` (free tier — https://aistudio.google.com)
- **Used by**: `crypto` agent (IG image generation)
```json
"mcp-image": {
  "command": "npx",
  "args": ["-y", "mcp-image"],
  "env": { "GEMINI_API_KEY": "<key>" }
}
```

## Configuration Format

MCP servers are managed by `mcporter`, NOT in `openclaw.json` directly.

```bash
# Add a stdio MCP server
mcporter config add <name> --command "npx" --arg "-y" --arg "<package>" --scope home

# List configured servers
mcporter list [--schema]

# Call a tool
mcporter call <server>.<tool>(key: "value")

# Remove a server
mcporter config remove <name>
```

Config file: `~/.mcporter/mcporter.json` (home scope) or `<project>/config/mcporter.json` (project scope)

## Recommended MCP Servers

### OneSearch (unified search)
```json
"onesearch": {
  "command": "npx",
  "args": ["-y", "@onesearch/mcp-server"]
}
```

### Context7 (library docs)
```json
"context7": {
  "command": "npx",
  "args": ["-y", "@context7/mcp-server"]
}
```

## Notes

- MCP servers run as child processes of OpenClaw
- Each server needs its own API keys (set via env vars)
- Verify servers come from trusted sources before installing
- Check https://docs.openclaw.ai for the latest supported MCP servers
