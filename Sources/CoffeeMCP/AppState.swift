import Foundation

actor AppState {
    var token: String?
    nonisolated let email: String?
    nonisolated let password: String?

    init() {
        let env = ProcessInfo.processInfo.environment
        token = env["COFFEE_JWT_TOKEN"]
        email = env["COFFEE_EMAIL"]
        password = env["COFFEE_PASSWORD"]
    }

    func setToken(_ t: String) {
        token = t
    }
}
