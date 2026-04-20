import Foundation

class SharedDataManager {
    static let shared = SharedDataManager()
    
    private let suiteName = "group.com.serverwatcher.shared"
    private let serversKey = "saved_servers"
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    func saveServers(_ servers: [ServerEntry]) {
        guard let data = try? JSONEncoder().encode(servers) else { return }
        userDefaults?.set(data, forKey: serversKey)
    }
    
    func loadServers() -> [ServerEntry] {
        guard let data = userDefaults?.data(forKey: serversKey),
              let servers = try? JSONDecoder().decode([ServerEntry].self, from: data) else {
            return []
        }
        return servers
    }
    
    func updateServerStatus(id: UUID, isOnline: Bool) {
        var servers = loadServers()
        if let index = servers.firstIndex(where: { $0.id == id }) {
            servers[index].isOnline = isOnline
            servers[index].lastChecked = Date()
            saveServers(servers)
        }
    }
}
