import Foundation
import Network

class NetworkChecker {
    static let shared = NetworkChecker()
    
    /// Check a single server's connectivity
    func checkServer(_ server: ServerEntry) async -> Bool {
        switch server.checkType {
        case .http:
            return await checkHTTP(server)
        case .tcp:
            return await checkTCP(server)
        }
    }
    
    /// Check all servers and return updated entries
    func checkAllServers(_ servers: [ServerEntry]) async -> [ServerEntry] {
        await withTaskGroup(of: (UUID, Bool).self) { group in
            for server in servers {
                group.addTask {
                    let result = await self.checkServer(server)
                    return (server.id, result)
                }
            }
            
            var results: [UUID: Bool] = [:]
            for await (id, isOnline) in group {
                results[id] = isOnline
            }
            
            return servers.map { server in
                var updated = server
                updated.isOnline = results[server.id]
                updated.lastChecked = Date()
                return updated
            }
        }
    }
    
    // MARK: - HTTP Check
    
    private func checkHTTP(_ server: ServerEntry) async -> Bool {
        var urlString = server.host
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://\(urlString)"
        }
        if let port = server.port {
            // Insert port into URL
            if let url = URL(string: urlString),
               var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                components.port = port
                urlString = components.string ?? urlString
            }
        }
        
        guard let url = URL(string: urlString) else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (100...599).contains(httpResponse.statusCode)
            }
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - TCP Check
    
    private func checkTCP(_ server: ServerEntry) async -> Bool {
        let port = server.port ?? 80
        let host = NWEndpoint.Host(server.host)
        let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))
        
        return await withCheckedContinuation { continuation in
            let connection = NWConnection(host: host, port: nwPort, using: .tcp)
            var resumed = false
            
            let queue = DispatchQueue(label: "tcp-check-\(server.id.uuidString)")
            
            // Set a timeout
            queue.asyncAfter(deadline: .now() + 10) {
                if !resumed {
                    resumed = true
                    connection.cancel()
                    continuation.resume(returning: false)
                }
            }
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if !resumed {
                        resumed = true
                        connection.cancel()
                        continuation.resume(returning: true)
                    }
                case .failed, .cancelled:
                    if !resumed {
                        resumed = true
                        connection.cancel()
                        continuation.resume(returning: false)
                    }
                default:
                    break
                }
            }
            
            connection.start(queue: queue)
        }
    }
}
