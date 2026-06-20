import Foundation
import MCP

// MARK: - Helpers

private func schema(_ properties: [String: Value], required: [String] = []) -> Value {
    var s: [String: Value] = [
        "type": .string("object"),
        "properties": .object(properties),
    ]
    if !required.isEmpty {
        s["required"] = .array(required.map { .string($0) })
    }
    return .object(s)
}

private func prop(_ type: String, description: String? = nil) -> Value {
    var d: [String: Value] = ["type": .string(type)]
    if let description { d["description"] = .string(description) }
    return .object(d)
}

private func decodeArgs<T: Decodable>(_ type: T.Type, from arguments: [String: Value]?) throws -> T {
    let dict = arguments ?? [:]
    let data = try JSONEncoder().encode(dict)
    return try JSONDecoder().decode(type, from: data)
}

private func jsonString(_ data: Data) -> String {
    String(data: data, encoding: .utf8) ?? "{}"
}

private func text(_ s: String) -> Tool.Content {
    .text(text: s, annotations: nil, _meta: nil)
}

// MARK: - Tool catalog

enum CoffeeTools {
    static let definitions: [Tool] = [

        // Auth / Users
        Tool(name: "login",
             description: "Authenticate with email and password. Stores the JWT token for this session.",
             inputSchema: schema(["email": prop("string", description: "User email"),
                                  "password": prop("string")],
                                 required: ["email", "password"])),

        Tool(name: "create_user",
             description: "Register a new user account.",
             inputSchema: schema(["email": prop("string"),
                                  "password": prop("string"),
                                  "name": prop("string"),
                                  "confirmPassword": prop("string")],
                                 required: ["email", "password", "name", "confirmPassword"])),

        Tool(name: "get_current_user",
             description: "Fetch the currently authenticated user's profile.",
             inputSchema: schema([:])),

        Tool(name: "get_user",
             description: "Fetch a user by ID.",
             inputSchema: schema(["id": prop("string", description: "User UUID")],
                                 required: ["id"])),

        // Groups
        Tool(name: "list_groups",
             description: "List all interest groups.",
             inputSchema: schema([:])),

        Tool(name: "get_group",
             description: "Fetch a single group by ID.",
             inputSchema: schema(["id": prop("string", description: "Group UUID")],
                                 required: ["id"])),

        Tool(name: "create_group",
             description: "Create a new interest group. Requires auth.",
             inputSchema: schema(["name": prop("string", description: "Display name"),
                                  "short": prop("string", description: "URL slug, e.g. sf-ios-coffee")],
                                 required: ["name", "short"])),

        Tool(name: "update_group",
             description: "Update an existing group. Requires auth.",
             inputSchema: schema(["id": prop("string"),
                                  "name": prop("string"),
                                  "short": prop("string"),
                                  "imageURL": prop("string")],
                                 required: ["id"])),

        Tool(name: "delete_group",
             description: "Delete a group by ID. Requires auth.",
             inputSchema: schema(["id": prop("string")],
                                 required: ["id"])),

        Tool(name: "get_group_events",
             description: "List events belonging to a group.",
             inputSchema: schema(["id": prop("string", description: "Group UUID")],
                                 required: ["id"])),

        Tool(name: "get_group_calendar",
             description: "Return the iCalendar (.ics) feed for a group.",
             inputSchema: schema(["id": prop("string", description: "Group UUID")],
                                 required: ["id"])),

        // Venues
        Tool(name: "list_venues",
             description: "List all venues.",
             inputSchema: schema([:])),

        Tool(name: "get_venue",
             description: "Fetch a venue by ID.",
             inputSchema: schema(["id": prop("string")],
                                 required: ["id"])),

        Tool(name: "create_venue",
             description: "Create a venue. Requires auth.",
             inputSchema: schema(["name": prop("string"),
                                  "address": prop("string", description: "Street address"),
                                  "title": prop("string", description: "Location display title (defaults to address)"),
                                  "latitude": prop("number"),
                                  "longitude": prop("number"),
                                  "applePlaceID": prop("string")],
                                 required: ["name", "address"])),

        // Events
        Tool(name: "list_events",
             description: "List all events.",
             inputSchema: schema([:])),

        Tool(name: "get_upcoming_events",
             description: "List upcoming (future) events.",
             inputSchema: schema([:])),

        Tool(name: "get_event",
             description: "Fetch a single event by ID.",
             inputSchema: schema(["id": prop("string")],
                                 required: ["id"])),

        Tool(name: "create_event",
             description: "Create an event. Requires auth.",
             inputSchema: schema(["group_id": prop("string", description: "Group UUID"),
                                  "venue_id": prop("string", description: "Venue UUID"),
                                  "name": prop("string"),
                                  "start_at": prop("string", description: "ISO 8601 datetime, e.g. 2026-06-01T10:00:00-07:00"),
                                  "end_at": prop("string", description: "ISO 8601 datetime")],
                                 required: ["group_id", "venue_id", "name", "start_at", "end_at"])),

        Tool(name: "update_event",
             description: "Update an event. Requires auth. All fields optional except id. Pass image_url as empty string to remove the image.",
             inputSchema: schema(["id": prop("string"),
                                  "group_id": prop("string"),
                                  "venue_id": prop("string", description: "Venue UUID"),
                                  "name": prop("string"),
                                  "start_at": prop("string"),
                                  "end_at": prop("string"),
                                  "image_url": prop("string")],
                                 required: ["id"])),

        Tool(name: "delete_event",
             description: "Delete an event. Requires auth.",
             inputSchema: schema(["id": prop("string")],
                                 required: ["id"])),

        // Search
        Tool(name: "search",
             description: "Search across events, venues, and interest groups.",
             inputSchema: schema(["query": prop("string", description: "Search terms")],
                                 required: ["query"])),

        // Tags
        Tool(name: "list_tags",
             description: "List all tags.",
             inputSchema: schema([:])),

        Tool(name: "create_tag",
             description: "Create a tag. Requires auth.",
             inputSchema: schema(["name": prop("string")],
                                 required: ["name"])),

        Tool(name: "attach_tag",
             description: "Attach a tag to a user. Requires auth.",
             inputSchema: schema(["tagID": prop("string"),
                                  "userID": prop("string")],
                                 required: ["tagID", "userID"])),

        Tool(name: "delete_tag",
             description: "Delete a tag. Requires auth.",
             inputSchema: schema(["id": prop("string")],
                                 required: ["id"])),

        // Media
        Tool(name: "upload_media",
             description: "Upload a local image file. Requires auth.",
             inputSchema: schema(["filePath": prop("string", description: "Absolute path to the image file")],
                                 required: ["filePath"])),

        Tool(name: "get_media_url",
             description: "Return the download URL for a media asset by ID (no network call).",
             inputSchema: schema(["id": prop("string", description: "Media UUID")],
                                 required: ["id"])),
    ]

    // MARK: - Handler

    static func handle(
        _ params: CallTool.Parameters,
        client: CoffeeClient,
        state: AppState
    ) async throws -> CallTool.Result {
        do {
            let s = try await route(params.name, args: params.arguments, client: client, state: state)
            return CallTool.Result(content: [text(s)])
        } catch let e as CoffeeError {
            return CallTool.Result(content: [text(e.localizedDescription)], isError: true)
        } catch {
            return CallTool.Result(content: [text(error.localizedDescription)], isError: true)
        }
    }

    // MARK: - Routing

    private static func route(
        _ name: String,
        args: [String: Value]?,
        client: CoffeeClient,
        state: AppState
    ) async throws -> String {
        switch name {

        // MARK: Auth / Users

        case "login":
            struct Args: Decodable { let email: String; let password: String }
            let a = try decodeArgs(Args.self, from: args)
            let data = try await client.request("users/login", method: "POST", basicAuth: (email: a.email, password: a.password))
            if let json = try? JSONDecoder().decode([String: Value].self, from: data),
               case .string(let token) = json["jwt-token"] {
                await state.setToken(token)
                return "Logged in. Token stored for this session."
            }
            return jsonString(data)

        case "create_user":
            struct Args: Decodable {
                let email: String; let password: String
                let name: String; let confirmPassword: String
            }
            let a = try decodeArgs(Args.self, from: args)
            let body = try JSONEncoder().encode([
                "email": a.email, "password": a.password,
                "name": a.name, "confirmPassword": a.confirmPassword,
            ])
            return jsonString(try await client.request("users", method: "POST", bodyData: body))

        case "get_current_user":
            let token = try await requireToken(state, client: client)
            return jsonString(try await client.request("users/me", token: token))

        case "get_user":
            struct Args: Decodable { let id: String }
            let a = try decodeArgs(Args.self, from: args)
            let token = try await requireToken(state, client: client)
            return jsonString(try await client.request("users/\(a.id)", token: token))

        // MARK: Groups

        case "list_groups":
            return jsonString(try await client.request("groups"))

        case "get_group":
            struct Args: Decodable { let id: String }
            let a = try decodeArgs(Args.self, from: args)
            return jsonString(try await client.request("groups/\(a.id)"))

        case "create_group":
            struct Args: Decodable { let name: String; let short: String }
            let a = try decodeArgs(Args.self, from: args)
            let token = try await requireToken(state, client: client)
            let body = try JSONEncoder().encode(["name": a.name, "short": a.short])
            return jsonString(try await client.request("groups", method: "POST", bodyData: body, token: token))

        case "update_group":
            struct Args: Decodable { let id: String; let name: String?; let short: String?; let imageURL: String? }
            let a = try decodeArgs(Args.self, from: args)
            let token = try await requireToken(state, client: client)
            var payload: [String: String] = [:]
            if let v = a.name { payload["name"] = v }
            if let v = a.short { payload["short"] = v }
            if let v = a.imageURL { payload["imageURL"] = v }
            let body = try JSONEncoder().encode(payload)
            return jsonString(try await client.request("groups/\(a.id)", method: "PATCH", bodyData: body, token: token))

        case "delete_group":
            struct Args: Decodable { let id: String }
            let a = try decodeArgs(Args.self, from: args)
            let token = try await requireToken(state, client: client)
            _ = try await client.request("groups/\(a.id)", method: "DELETE", token: token)
            return "Group \(a.id) deleted."

        case "get_group_events":
            struct Args: Decodable { let id: String }
            let a = try decodeArgs(Args.self, from: args)
            return jsonString(try await client.request("groups/\(a.id)/events"))

        case "get_group_calendar":
            struct Args: Decodable { let id: String }
            let a = try decodeArgs(Args.self, from: args)
            let data = try await client.request("groups/\(a.id)/calendar.ics/")
            return String(data: data, encoding: .utf8) ?? "<binary data>"

        // MARK: Venues

        case "list_venues":
            return jsonString(try await client.request("venues"))

        case "get_venue":
            struct Args: Decodable { let id: String }
            let a = try decodeArgs(Args.self, from: args)
            return jsonString(try await client.request("venues/\(a.id)"))

        case "create_venue":
            struct Args: Decodable {
                let name: String; let address: String; let title: String?
                let latitude: Double?; let longitude: Double?; let applePlaceID: String?
            }
            let a = try decodeArgs(Args.self, from: args)
            let token = try await requireToken(state, client: client)
            var location: [String: Any] = ["address": a.address, "title": a.title ?? a.address]
            if let lat = a.latitude { location["latitude"] = lat }
            if let lon = a.longitude { location["longitude"] = lon }
            var payload: [String: Any] = ["name": a.name, "location": location]
            if let pid = a.applePlaceID { payload["applePlaceID"] = pid }
            let body = try JSONSerialization.data(withJSONObject: payload)
            return jsonString(try await client.request("venues", method: "POST", bodyData: body, token: token))

        // MARK: Events

        case "list_events":
            return jsonString(try await client.request("events"))

        case "get_upcoming_events":
            return jsonString(try await client.request("events/upcoming"))

        case "get_event":
            struct Args: Decodable { let id: String }
            let a = try decodeArgs(Args.self, from: args)
            return jsonString(try await client.request("events/\(a.id)"))

        case "create_event":
            struct Args: Decodable {
                let group_id: String; let venue_id: String
                let name: String; let start_at: String; let end_at: String
            }
            let a = try decodeArgs(Args.self, from: args)
            let token = try await requireToken(state, client: client)
            let payload: [String: Any] = [
                "group_id": a.group_id,
                "venue": ["id": a.venue_id],
                "name": a.name,
                "start_at": a.start_at,
                "end_at": a.end_at,
            ]
            let body = try JSONSerialization.data(withJSONObject: payload)
            return jsonString(try await client.request("events", method: "POST", bodyData: body, token: token))

        case "update_event":
            struct Args: Decodable {
                let id: String; let group_id: String?; let venue_id: String?
                let name: String?; let start_at: String?; let end_at: String?; let image_url: String?
            }
            let a = try decodeArgs(Args.self, from: args)
            let token = try await requireToken(state, client: client)
            var payload: [String: Any] = [:]
            if let v = a.group_id { payload["group_id"] = v }
            if let v = a.venue_id { payload["venue"] = ["id": v] }
            if let v = a.name { payload["name"] = v }
            if let v = a.start_at { payload["start_at"] = v }
            if let v = a.end_at { payload["end_at"] = v }
            if let v = a.image_url { payload["image_url"] = v.isEmpty ? NSNull() : v }
            let body = try JSONSerialization.data(withJSONObject: payload)
            return jsonString(try await client.request("events/\(a.id)", method: "PUT", bodyData: body, token: token))

        case "delete_event":
            struct Args: Decodable { let id: String }
            let a = try decodeArgs(Args.self, from: args)
            let token = try await requireToken(state, client: client)
            _ = try await client.request("events/\(a.id)", method: "DELETE", token: token)
            return "Event \(a.id) deleted."

        // MARK: Search

        case "search":
            struct Args: Decodable { let query: String }
            let a = try decodeArgs(Args.self, from: args)
            let data = try await client.request(
                "search",
                method: "POST",
                queryItems: [URLQueryItem(name: "searchTerms", value: a.query)]
            )
            return jsonString(data)

        // MARK: Tags

        case "list_tags":
            return jsonString(try await client.request("tags"))

        case "create_tag":
            struct Args: Decodable { let name: String }
            let a = try decodeArgs(Args.self, from: args)
            let token = try await requireToken(state, client: client)
            let body = try JSONEncoder().encode(["name": a.name])
            return jsonString(try await client.request("tags", method: "POST", bodyData: body, token: token))

        case "attach_tag":
            struct Args: Decodable { let tagID: String; let userID: String }
            let a = try decodeArgs(Args.self, from: args)
            let token = try await requireToken(state, client: client)
            return jsonString(try await client.request("tags/\(a.tagID)/attach/\(a.userID)", method: "POST", token: token))

        case "delete_tag":
            struct Args: Decodable { let id: String }
            let a = try decodeArgs(Args.self, from: args)
            let token = try await requireToken(state, client: client)
            _ = try await client.request("tags/\(a.id)", method: "DELETE", token: token)
            return "Tag \(a.id) deleted."

        // MARK: Media

        case "upload_media":
            struct Args: Decodable { let filePath: String }
            let a = try decodeArgs(Args.self, from: args)
            let token = try await requireToken(state, client: client)
            let fileURL = URL(fileURLWithPath: a.filePath)
            return jsonString(try await client.requestMultipart("media/upload", fileURL: fileURL, token: token))

        case "get_media_url":
            struct Args: Decodable { let id: String }
            let a = try decodeArgs(Args.self, from: args)
            return "/api/v2/media/\(a.id)"

        default:
            throw CoffeeError.httpError(0, "Unknown tool: \(name)")
        }
    }

    private static func requireToken(_ state: AppState, client: CoffeeClient) async throws -> String {
        if let t = await state.token { return t }
        if let email = state.email, let password = state.password {
            let data = try await client.request(
                "users/login",
                method: "POST",
                basicAuth: (email: email, password: password)
            )
            if let json = try? JSONDecoder().decode([String: Value].self, from: data),
               case .string(let token) = json["jwt-token"] {
                await state.setToken(token)
                return token
            }
        }
        throw CoffeeError.missingToken
    }
}
