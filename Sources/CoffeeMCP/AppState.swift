import Foundation

actor AppState {
    var token: String?

    init() {
        token = ProcessInfo.processInfo.environment["COFFEE_JWT_TOKEN"]
    }

    func setToken(_ t: String) {
        token = t
    }
}
