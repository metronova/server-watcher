import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct ServerStatusEntry: TimelineEntry {
    let date: Date
    let servers: [ServerEntry]
}

// MARK: - Timeline Provider

struct ServerStatusProvider: TimelineProvider {
    let dataManager = SharedDataManager.shared

    func placeholder(in context: Context) -> ServerStatusEntry {
        ServerStatusEntry(date: Date(), servers: ServerEntry.examples)
    }

    func getSnapshot(in context: Context, completion: @escaping (ServerStatusEntry) -> Void) {
        let servers = dataManager.loadServers()
        if servers.isEmpty {
            completion(ServerStatusEntry(date: Date(), servers: ServerEntry.examples))
        } else {
            completion(ServerStatusEntry(date: Date(), servers: servers))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ServerStatusEntry>) -> Void) {
        let servers = dataManager.loadServers()
        let checker = NetworkChecker.shared

        Task {
            let updatedServers = await checker.checkAllServers(servers)
            dataManager.saveServers(updatedServers)

            let entry = ServerStatusEntry(date: Date(), servers: updatedServers)
            // Refresh every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - Widget Views

struct ServerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ServerStatusProvider.Entry

    var maxItems: Int {
        switch family {
        case .systemSmall:
            return 3
        case .systemMedium:
            return 5
        case .systemLarge:
            return 10
        case .systemExtraLarge:
            return 14
        @unknown default:
            return 5
        }
    }

    var displayServers: [ServerEntry] {
        Array(entry.servers.prefix(maxItems))
    }

    var body: some View {
        if entry.servers.isEmpty {
            emptyView
        } else {
            switch family {
            case .systemSmall:
                smallWidgetView
            case .systemMedium:
                mediumWidgetView
            case .systemLarge:
                largeWidgetView
            default:
                mediumWidgetView
            }
        }
    }

    // MARK: - Empty State

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "server.rack")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("尚未添加伺服器")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Small Widget

    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "server.rack")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Server Watcher")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.bottom, 4)

            ForEach(displayServers) { server in
                compactServerRow(server: server)
                if server.id != displayServers.last?.id {
                    Divider()
                        .padding(.vertical, 2)
                }
            }

            Spacer(minLength: 0)

            if entry.servers.count > maxItems {
                Text("還有 \(entry.servers.count - maxItems) 個...")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(8)
    }

    // MARK: - Medium Widget

    private var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
                .padding(.bottom, 4)

            let columns = splitIntoColumns(displayServers, count: 2)

            HStack(alignment: .top, spacing: 12) {
                ForEach(0..<columns.count, id: \.self) { colIndex in
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(columns[colIndex]) { server in
                            serverRow(server: server)
                            if server.id != columns[colIndex].last?.id {
                                Divider()
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    if colIndex < columns.count - 1 {
                        Divider()
                    }
                }
            }

            Spacer(minLength: 0)

            footerView
        }
        .padding(10)
    }

    // MARK: - Large Widget

    private var largeWidgetView: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
                .padding(.bottom, 4)

            ForEach(displayServers) { server in
                detailedServerRow(server: server)
                if server.id != displayServers.last?.id {
                    Divider()
                        .padding(.vertical, 3)
                }
            }

            Spacer(minLength: 0)

            footerView
        }
        .padding(12)
    }

    // MARK: - Header & Footer

    private var headerView: some View {
        HStack {
            Image(systemName: "server.rack")
                .font(.caption2)
            Text("Server Watcher")
                .font(.caption)
                .fontWeight(.semibold)
            Spacer()
            statusSummary
        }
        .foregroundStyle(.secondary)
    }

    private var statusSummary: some View {
        let onlineCount = entry.servers.filter { $0.isOnline == true }.count
        let totalCount = entry.servers.count
        return HStack(spacing: 4) {
            Circle()
                .fill(onlineCount == totalCount ? .green : .orange)
                .frame(width: 6, height: 6)
            Text("\(onlineCount)/\(totalCount)")
                .font(.caption2)
                .fontWeight(.medium)
        }
    }

    private var footerView: some View {
        Group {
            if entry.servers.count > maxItems {
                HStack {
                    Spacer()
                    Text("還有 \(entry.servers.count - maxItems) 個伺服器")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Row Views

    private func compactServerRow(server: ServerEntry) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor(for: server))
                .frame(width: 8, height: 8)
            Text(server.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            Spacer()
        }
        .padding(.vertical, 1)
    }

    private func serverRow(server: ServerEntry) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor(for: server))
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(server.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(server.displayHost)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer()
            Text(statusText(for: server))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(statusColor(for: server))
        }
        .padding(.vertical, 2)
    }

    private func detailedServerRow(server: ServerEntry) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor(for: server))
                .frame(width: 10, height: 10)
                .shadow(color: statusColor(for: server).opacity(0.4), radius: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(server.checkType.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                        )
                    Text(server.displayHost)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(statusText(for: server))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor(for: server))
                if let lastChecked = server.lastChecked {
                    Text(lastChecked, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 1)
    }

    // MARK: - Helpers

    private func statusColor(for server: ServerEntry) -> Color {
        guard let isOnline = server.isOnline else { return .gray }
        return isOnline ? .green : .red
    }

    private func statusText(for server: ServerEntry) -> String {
        guard let isOnline = server.isOnline else { return "—" }
        return isOnline ? "在線" : "離線"
    }

    private func splitIntoColumns(_ items: [ServerEntry], count: Int) -> [[ServerEntry]] {
        guard count > 0 else { return [items] }
        var columns: [[ServerEntry]] = Array(repeating: [], count: count)
        for (index, item) in items.enumerated() {
            columns[index % count].append(item)
        }
        return columns.filter { !$0.isEmpty }
    }
}

// MARK: - Widget Configuration

struct ServerWatcherWidget: Widget {
    let kind: String = "ServerWatcherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ServerStatusProvider()) { entry in
            ServerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("伺服器監控")
        .description("顯示伺服器的連接狀態列表")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    ServerWatcherWidget()
} timeline: {
    ServerStatusEntry(date: Date(), servers: ServerEntry.examples)
}

#Preview("Medium", as: .systemMedium) {
    ServerWatcherWidget()
} timeline: {
    ServerStatusEntry(date: Date(), servers: ServerEntry.examples)
}

#Preview("Large", as: .systemLarge) {
    ServerWatcherWidget()
} timeline: {
    ServerStatusEntry(date: Date(), servers: ServerEntry.examples)
}
