# MCP Server Configuration

> MCP (Model Context Protocol) servers extend OpenClaw with external tool access.
> Add MCP server configs to the `mcpServers` section in `openclaw.json`.

## Currently Configured

_None yet - fresh install._

## Configuration Format

In `~/.openclaw/openclaw.json`:

```json
{
  "mcpServers": {
    "<server-name>": {
      "command": "npx",
      "args": ["-y", "@scope/mcp-server-package"]
    }
  }
}
```

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
