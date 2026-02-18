# MCP Server Configuration

> MCP (Model Context Protocol) servers extend OpenClaw with external tool access.
> Add MCP server configs to the `mcpServers` section in `openclaw.json`.

## Currently Configured

### Apple Shortcuts (run macOS Shortcuts)
- **Repo**: https://github.com/recursechat/mcp-server-apple-shortcuts
- **Stars**: 301 | **License**: Apache-2.0
- **Tools**: list shortcuts, run shortcut by name (with optional input)
- **Use case**: Execute pre-built HomeKit shortcuts to control smart home devices without creating a separate HomeKit pairing
```json
"apple-shortcuts": {
  "command": "npx",
  "args": ["-y", "mcp-server-apple-shortcuts"]
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
