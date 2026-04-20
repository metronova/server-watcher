import Foundation

enum CheckType: String, Codable, CaseIterable, Identifiable {
    case http = "HTTP"
    case tcp = "TCP"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .http: return "HTTP(S)"
        case .tcp: return "TCP Port"
        }
    }
}

struct ServerEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var host: String
    var port: Int?
    var checkType: CheckType = .http
    var isOnline: Bool? = nil
    var lastChecked: Date? = nil

    var displayHost: String {
        if let port = port {
            return "\(host):\(port)"
        }
        return host
    }

    static func == (lhs: ServerEntry, rhs: ServerEntry) -> Bool {
        lhs.id == rhs.id
    }

    static let example = ServerEntry(
        name: "Google",
        host: "https://www.google.com",
        port: nil,
        checkType: .http,
        isOnline: true,
        lastChecked: Date()
    )

    static let examples: [ServerEntry] = [
        ServerEntry(name: "Google", host: "https://www.google.com", checkType: .http, isOnline: true, lastChecked: Date()),
        ServerEntry(name: "GitHub", host: "https://github.com", checkType: .http, isOnline: true, lastChecked: Date()),
        ServerEntry(name: "Database", host: "192.168.1.100", port: 5432, checkType: .tcp, isOnline: false, lastChecked: Date()),
        ServerEntry(name: "Redis", host: "192.168.1.100", port: 6379, checkType: .tcp, isOnline: true, lastChecked: Date()),
        ServerEntry(name: "API Server", host: "https://api.example.com", checkType: .http, isOnline: nil),
        ServerEntry(name: "SSH Server", host: "10.0.0.5", port: 22, checkType: .tcp, isOnline: true, lastChecked: Date()),
    ]
}
