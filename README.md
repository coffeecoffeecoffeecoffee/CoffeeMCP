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

Add to your MCP config (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "coffee": {
      "command": "/opt/homebrew/bin/coffee-mcp"
    }
  }
}
```

If you built from source, use the path to `.build/release/CoffeeMCP` instead.

Then ask Claude about coffee events, groups, venues, and more.

## Configuration

| Environment Variable | Default | Description |
|---|---|---|
| `COFFEE_BASE_URL` | `https://www.coffeecoffeecoffee.coffee/api/v2/` | API base URL |
| `COFFEE_JWT_TOKEN` | — | Auth token (or use the `login` tool at runtime) |

## License

MIT — see [LICENSE](LICENSE).
