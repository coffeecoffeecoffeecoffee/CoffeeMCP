import MCP
import Foundation

@main
struct CoffeeMCPServer {
    static let version = "1.0.0"

    static func main() async throws {
        // Handle CLI flags before starting the stdio transport so tools like
        // `brew test` (and `coffee-mcp --version`) get a prompt response and exit.
        let arguments = CommandLine.arguments.dropFirst()
        if arguments.contains("--version") || arguments.contains("-v") {
            print("coffee-mcp \(version)")
            return
        }
        if arguments.contains("--help") || arguments.contains("-h") {
            printUsage()
            return
        }

        let state = AppState()
        let client = CoffeeClient()

        let server = Server(
            name: "coffee-mcp",
            version: version,
            capabilities: Server.Capabilities(tools: .init())
        )

        await server.withMethodHandler(ListTools.self) { _ in
            ListTools.Result(tools: CoffeeTools.definitions)
        }
        await server.withMethodHandler(CallTool.self) { params in
            try await CoffeeTools.handle(params, client: client, state: state)
        }

        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }

    static func printUsage() {
        print("""
        coffee-mcp \(version)
        A Model Context Protocol server for the Coffee API.

        Usage:
          coffee-mcp            Start the MCP server over stdio (default)
          coffee-mcp --version  Print the version and exit
          coffee-mcp --help     Print this help and exit

        Configuration is via environment variables (COFFEE_BASE_URL,
        COFFEE_JWT_TOKEN, COFFEE_EMAIL, COFFEE_PASSWORD). See the README.
        """)
    }
}
