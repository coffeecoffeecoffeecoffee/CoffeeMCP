# CoffeeMCP

A [Model Context Protocol](https://modelcontextprotocol.io) (MCP) server for the [Coffee](https://www.coffeecoffeecoffee.coffee) API, written in Swift.

## Requirements

- macOS 13+
- Swift 6.0+

## Installation

```bash
git clone <repo-url>
cd CoffeeMCP
swift build -c release
```

The binary will be at `.build/release/CoffeeMCP`.

## Configuration

| Environment Variable | Default | Description |
|---|---|---|
| `COFFEE_BASE_URL` | `https://www.coffeecoffeecoffee.coffee/api/v2/` | API base URL |
| `COFFEE_JWT_TOKEN` | — | Auth token (or use the `login` tool at runtime) |

## Usage with Claude

Add to your MCP config (e.g. `~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "coffee": {
      "command": "/path/to/.build/release/CoffeeMCP"
    }
  }
}
```

Then ask Claude about coffee events, groups, venues, and more.

## License

MIT — see [LICENSE](LICENSE).
