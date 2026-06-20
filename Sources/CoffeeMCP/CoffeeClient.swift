import Foundation

enum CoffeeError: Error, LocalizedError {
    case httpError(Int, String)
    case missingToken

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let body): "HTTP \(code): \(body)"
        case .missingToken: "No auth token — call login first, or set COFFEE_JWT_TOKEN, or set COFFEE_EMAIL and COFFEE_PASSWORD"
        }
    }
}

final class CoffeeClient: Sendable {
    let baseURL: URL

    init() {
        let raw = ProcessInfo.processInfo.environment["COFFEE_BASE_URL"]
            ?? "https://www.coffeecoffeecoffee.coffee/api/v2/"
        baseURL = URL(string: raw)!
    }

    func request(
        _ path: String,
        method: String = "GET",
        queryItems: [URLQueryItem]? = nil,
        bodyData: Data? = nil,
        token: String? = nil,
        basicAuth: (email: String, password: String)? = nil
    ) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if let queryItems { components.queryItems = queryItems }

        var req = URLRequest(url: components.url!)
        req.httpMethod = method
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let basicAuth {
            let credentials = Data("\(basicAuth.email):\(basicAuth.password)".utf8).base64EncodedString()
            req.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = bodyData

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as! HTTPURLResponse).statusCode
        guard (200..<300).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw CoffeeError.httpError(status, body)
        }
        return data
    }

    func requestMultipart(
        _ path: String,
        fileURL: URL,
        token: String
    ) async throws -> Data {
        let boundary = UUID().uuidString
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(fileURL.lastPathComponent, forHTTPHeaderField: "File-Name")

        let fileData = try Data(contentsOf: fileURL)
        let mimeType = mimeType(for: fileURL)
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as! HTTPURLResponse).statusCode
        guard (200..<300).contains(status) else {
            let b = String(data: data, encoding: .utf8) ?? ""
            throw CoffeeError.httpError(status, b)
        }
        return data
    }

    private func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        default: return "application/octet-stream"
        }
    }
}
