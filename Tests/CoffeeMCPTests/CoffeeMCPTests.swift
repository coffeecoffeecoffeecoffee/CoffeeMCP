import Foundation
import Testing
import MCP
@testable import CoffeeMCP

// MARK: - CoffeeError

@Suite("CoffeeError")
struct CoffeeErrorTests {
    @Test("missingToken description names every supported auth source")
    func missingTokenDescription() {
        let description = CoffeeError.missingToken.errorDescription ?? ""
        #expect(description.contains("login"))
        #expect(description.contains("COFFEE_JWT_TOKEN"))
        #expect(description.contains("COFFEE_EMAIL"))
        #expect(description.contains("COFFEE_PASSWORD"))
    }

    @Test("httpError description includes status and body")
    func httpErrorDescription() {
        let err = CoffeeError.httpError(404, "not found")
        #expect(err.errorDescription == "HTTP 404: not found")
    }
}

// MARK: - Tool catalog

@Suite("CoffeeTools catalog")
struct CoffeeToolsCatalogTests {
    @Test("tool names are unique")
    func uniqueNames() {
        let names = CoffeeTools.definitions.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test("catalog includes the core tools")
    func coreToolsPresent() {
        let names = Set(CoffeeTools.definitions.map(\.name))
        for required in ["login", "create_user", "get_current_user",
                         "list_groups", "list_events", "list_venues",
                         "search", "upload_media", "get_media_url"] {
            #expect(names.contains(required), "missing tool \(required)")
        }
    }

    @Test("login schema requires email and password")
    func loginSchemaRequiredFields() throws {
        let login = try #require(CoffeeTools.definitions.first { $0.name == "login" })
        let required = requiredFields(of: login.inputSchema)
        #expect(required.contains("email"))
        #expect(required.contains("password"))
    }

    @Test("every tool's inputSchema is a JSON object")
    func everySchemaIsObject() {
        for tool in CoffeeTools.definitions {
            guard case .object(let schema) = tool.inputSchema,
                  case .string(let type) = schema["type"] else {
                Issue.record("\(tool.name) inputSchema is not an object")
                continue
            }
            #expect(type == "object", "\(tool.name) schema type should be 'object'")
        }
    }

    private func requiredFields(of schema: Value) -> [String] {
        guard case .object(let dict) = schema,
              case .array(let items) = dict["required"] else { return [] }
        return items.compactMap {
            if case .string(let s) = $0 { return s } else { return nil }
        }
    }
}

// Env vars are process-global, so suites that mutate them must run serially —
// both within themselves and against sibling suites that touch the same vars.
@Suite("Env-driven behavior", .serialized)
struct EnvDrivenTests {

    @Suite("AppState")
    struct AppStateTests {
        @Test("token, email, and password are nil when env is unset")
        func nilByDefault() async {
            unsetenv("COFFEE_JWT_TOKEN")
            unsetenv("COFFEE_EMAIL")
            unsetenv("COFFEE_PASSWORD")
            let state = AppState()
            await #expect(state.token == nil)
            #expect(state.email == nil)
            #expect(state.password == nil)
        }

        @Test("reads JWT token from environment")
        func tokenFromEnv() async {
            setenv("COFFEE_JWT_TOKEN", "jwt-xyz", 1)
            defer { unsetenv("COFFEE_JWT_TOKEN") }
            let state = AppState()
            await #expect(state.token == "jwt-xyz")
        }

        @Test("reads email and password from environment")
        func credentialsFromEnv() async {
            setenv("COFFEE_EMAIL", "test@example.com", 1)
            setenv("COFFEE_PASSWORD", "hunter2", 1)
            defer {
                unsetenv("COFFEE_EMAIL")
                unsetenv("COFFEE_PASSWORD")
            }
            let state = AppState()
            #expect(state.email == "test@example.com")
            #expect(state.password == "hunter2")
        }

        @Test("setToken updates the stored token")
        func setTokenUpdates() async {
            unsetenv("COFFEE_JWT_TOKEN")
            let state = AppState()
            await state.setToken("freshly-minted")
            await #expect(state.token == "freshly-minted")
        }
    }

    @Suite("CoffeeClient")
    struct CoffeeClientTests {
        @Test("defaults to the production base URL")
        func defaultBaseURL() {
            unsetenv("COFFEE_BASE_URL")
            let client = CoffeeClient()
            #expect(client.baseURL.absoluteString == "https://www.coffeecoffeecoffee.coffee/api/v2/")
        }

        @Test("base URL is overridable via COFFEE_BASE_URL")
        func baseURLFromEnv() {
            setenv("COFFEE_BASE_URL", "https://staging.example.com/api/", 1)
            defer { unsetenv("COFFEE_BASE_URL") }
            let client = CoffeeClient()
            #expect(client.baseURL.absoluteString == "https://staging.example.com/api/")
        }
    }

    @Suite("Tool routing")
    struct ToolRoutingTests {
        @Test("unknown tool name returns an error result")
        func unknownTool() async throws {
            let result = try await callTool(name: "does_not_exist")
            #expect(result.isError == true)
        }

        @Test("get_media_url returns a deterministic path without network access")
        func getMediaURLOffline() async throws {
            let result = try await callTool(
                name: "get_media_url",
                arguments: ["id": .string("abc-123")]
            )
            #expect(result.isError != true)
            #expect(textContent(of: result) == "/api/v2/media/abc-123")
        }

        @Test("auth-required tool reports missing token when no credentials are set")
        func missingTokenSurfaced() async throws {
            unsetenv("COFFEE_JWT_TOKEN")
            unsetenv("COFFEE_EMAIL")
            unsetenv("COFFEE_PASSWORD")
            let result = try await callTool(name: "get_current_user")
            #expect(result.isError == true)
            let body = textContent(of: result) ?? ""
            #expect(body.contains("No auth token"))
        }

        // MARK: helpers

        private func callTool(
            name: String,
            arguments: [String: Value]? = nil
        ) async throws -> CallTool.Result {
            let client = CoffeeClient()
            let state = AppState()
            let params = CallTool.Parameters(name: name, arguments: arguments)
            return try await CoffeeTools.handle(params, client: client, state: state)
        }

        private func textContent(of result: CallTool.Result) -> String? {
            guard case .text(let text, _, _) = result.content.first else { return nil }
            return text
        }
    }
}
