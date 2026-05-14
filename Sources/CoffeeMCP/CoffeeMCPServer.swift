import MCP
import Foundation

@main
struct CoffeeMCPServer {
    static func main() async throws {
        let state = AppState()
        let client = CoffeeClient()

        let server = Server(
            name: "coffee-mcp",
            version: "1.0.0",
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
}
