import Foundation
import Combine
import WidgetKit

@MainActor
class ServerViewModel: ObservableObject {
    @Published var servers: [ServerEntry] = []
    @Published var isChecking = false

    private let dataManager = SharedDataManager.shared
    private let networkChecker = NetworkChecker.shared
    private var autoCheckTimer: Timer?

    init() {
        loadServers()
        startAutoCheck()
    }

    deinit {
        autoCheckTimer?.invalidate()
    }

    func loadServers() {
        servers = dataManager.loadServers()
    }

    func addServer(_ server: ServerEntry) {
        servers.append(server)
        saveAndNotify()
        Task { await checkServer(server) }
    }

    func updateServer(_ server: ServerEntry) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            saveAndNotify()
            Task { await checkServer(server) }
        }
    }

    func deleteServer(_ server: ServerEntry) {
        servers.removeAll { $0.id == server.id }
        saveAndNotify()
    }

    func moveServer(from source: IndexSet, to destination: Int) {
        servers.move(fromOffsets: source, toOffset: destination)
        saveAndNotify()
    }

    func checkServer(_ server: ServerEntry) async {
        let result = await networkChecker.checkServer(server)
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index].isOnline = result
            servers[index].lastChecked = Date()
            saveAndNotify()
        }
    }

    func checkAllServers() async {
        guard !isChecking else { return }
        isChecking = true
        servers = await networkChecker.checkAllServers(servers)
        saveAndNotify()
        isChecking = false
    }

    private func saveAndNotify() {
        dataManager.saveServers(servers)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func startAutoCheck() {
        // Auto check every 5 minutes
        autoCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkAllServers()
            }
        }
    }
}
