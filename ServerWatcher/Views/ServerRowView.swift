import SwiftUI

struct ServerRowView: View {
    @EnvironmentObject var settings: AppSettings
    let server: ServerEntry
    let onCheck: () -> Void

    private var s: L10nStrings { settings.strings }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .shadow(color: statusColor.opacity(0.5), radius: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                    .font(.headline)

                HStack(spacing: 6) {
                    Text(server.checkType.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                        )

                    Text(server.displayHost)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(statusText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(statusColor)

                if let latency = server.latencyMs {
                    Text(latencyText(latency))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(latencyColor(latency))
                }
                if let lastChecked = server.lastChecked {
                    Text(lastChecked, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        guard let isOnline = server.isOnline else {
            return .gray
        }
        return isOnline ? .green : .red
    }

    private var statusText: String {
        guard let isOnline = server.isOnline else {
            return s.notChecked
        }
        return isOnline ? s.online : s.offline
    }

    private func latencyText(_ ms: Double) -> String {
        if ms < 1000 {
            return String(format: "%.0f ms", ms)
        } else {
            return String(format: "%.1f s", ms / 1000)
        }
    }

    private func latencyColor(_ ms: Double) -> Color {
        switch ms {
        case ..<100:  return .green
        case ..<500:  return .orange
        default:      return .red
        }
    }
}

#Preview {
    List {
        ServerRowView(server: .example) {}
        ServerRowView(server: ServerEntry(name: "Offline Server", host: "192.168.1.1", port: 8080, checkType: .tcp, isOnline: false, lastChecked: Date())) {}
        ServerRowView(server: ServerEntry(name: "Unknown", host: "example.com", checkType: .http)) {}
    }
    .environmentObject(AppSettings.shared)
}
