import Foundation
import Network

class NetworkChecker {
    static let shared = NetworkChecker()

    private final class TCPCheckState: @unchecked Sendable {
        var resumed = false
        var isReady = false
    }
    
    /// Check a single server's connectivity, returning (isOnline, latencyMs)
    func checkServer(_ server: ServerEntry) async -> (Bool, Double?) {
        switch server.checkType {
        case .http:
            return await checkHTTP(server)
        case .tcp:
            return await checkTCP(server)
        }
    }
    
    /// Check all servers and return updated entries
    func checkAllServers(_ servers: [ServerEntry]) async -> [ServerEntry] {
        await withTaskGroup(of: (UUID, Bool, Double?).self) { group in
            for server in servers {
                group.addTask {
                    let (isOnline, latency) = await self.checkServer(server)
                    return (server.id, isOnline, latency)
                }
            }
            
            var results: [UUID: (Bool, Double?)] = [:]
            for await (id, isOnline, latency) in group {
                results[id] = (isOnline, latency)
            }
            
            return servers.map { server in
                var updated = server
                updated.isOnline = results[server.id]?.0
                updated.latencyMs = results[server.id]?.1
                updated.lastChecked = Date()
                return updated
            }
        }
    }
    
    // MARK: - HTTP Check
    
    private func checkHTTP(_ server: ServerEntry) async -> (Bool, Double?) {
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
        
        guard let url = URL(string: urlString) else { return (false, nil) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        
        let start = Date()
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let latency = Date().timeIntervalSince(start) * 1000
            if let httpResponse = response as? HTTPURLResponse {
                return (httpResponse.statusCode == 200, latency)
            }
            return (false, latency)
        } catch {
            return (false, nil)
        }
    }
    
    // MARK: - TCP Check
    
    private func checkTCP(_ server: ServerEntry) async -> (Bool, Double?) {
        let timeoutInterval: TimeInterval = 10
        let stabilityInterval: TimeInterval = 1
        let port = server.port ?? 80
        let host = NWEndpoint.Host(server.host)
        let nwPort = NWEndpoint.Port(integerLiteral: UInt16(port))
        let start = Date()
        
        return await withCheckedContinuation { continuation in
            let connection = NWConnection(host: host, port: nwPort, using: .tcp)
            let checkState = TCPCheckState()
            
            let queue = DispatchQueue(label: "tcp-check-\(server.id.uuidString)")

            func finish(_ result: (Bool, Double?)) {
                guard !checkState.resumed else { return }
                checkState.resumed = true
                connection.cancel()
                continuation.resume(returning: result)
            }

            func watchForEarlyClose() {
                connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { _, _, isComplete, error in
                    guard !checkState.resumed else { return }
                    if isComplete || error != nil {
                        finish((false, nil))
                        return
                    }
                    watchForEarlyClose()
                }
            }
            
            queue.asyncAfter(deadline: .now() + timeoutInterval) {
                finish((false, nil))
            }
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if !checkState.resumed && !checkState.isReady {
                        checkState.isReady = true
                        let latency = Date().timeIntervalSince(start) * 1000
                        watchForEarlyClose()
                        queue.asyncAfter(deadline: .now() + stabilityInterval) {
                            finish((true, latency))
                        }
                    }
                case .waiting, .failed, .cancelled:
                    finish((false, nil))
                default:
                    break
                }
            }
            
            connection.start(queue: queue)
        }
    }
}
