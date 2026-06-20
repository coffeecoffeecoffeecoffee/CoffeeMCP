# CoffeeMCP

A [Model Context Protocol](https://modelcontextprotocol.io) (MCP) server for the [Coffee](https://www.coffeecoffeecoffee.coffee) API, written in Swift.

## Installation

### Homebrew (recommended)

```bash
brew tap coffeecoffeecoffeecoffee/tap
brew install coffee-mcp
```

### Build from source

Requires macOS 13+ and Swift 6.0+.

```bash
git clone https://github.com/coffeecoffeecoffeecoffee/CoffeeMCP.git
cd CoffeeMCP
swift build -c release
```

The binary will be at `.build/release/CoffeeMCP`.

## Usage with Claude Desktop

Add to your MCP config (`~/Library/Application Support/Claude/claude_desktop_config.json`).
The server supports the standard MCP server properties — `command`, `args`, and `env`:

```json
{
  "mcpServers": {
    "coffee": {
      "command": "/opt/homebrew/bin/coffee-mcp",
      "args": [],
      "env": {
        "COFFEE_EMAIL": "you@example.com",
        "COFFEE_PASSWORD": "your-password"
      }
    }
  }
}
```

If you built from source, use the path to `.build/release/CoffeeMCP` instead.

Then ask Claude about coffee events, groups, venues, and more.

## Configuration

Credentials are read from environment variables — pass them via the `env` block of your
MCP config (above). All variables are optional; unauthenticated calls still work for
public endpoints.

| Environment Variable | Default | Description |
|---|---|---|
| `COFFEE_BASE_URL` | `https://www.coffeecoffeecoffee.coffee/api/v2/` | API base URL |
| `COFFEE_JWT_TOKEN` | — | Pre-issued JWT auth token. Takes precedence over email/password. |
| `COFFEE_EMAIL` | — | Account email. Combined with `COFFEE_PASSWORD`, the server logs in automatically on the first authenticated tool call. |
| `COFFEE_PASSWORD` | — | Account password (paired with `COFFEE_EMAIL`). |

You can also call the `login` tool at runtime instead of providing credentials in env.

## License

MIT — see [LICENSE](LICENSE).
