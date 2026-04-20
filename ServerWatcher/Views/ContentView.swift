import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ServerViewModel()
    @State private var showingAddServer = false
    @State private var editingServer: ServerEntry? = nil

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.servers.isEmpty {
                    emptyStateView
                } else {
                    serverListView
                }
            }
            .navigationTitle("Server Watcher")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddServer = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.servers.isEmpty {
                        Button {
                            Task { await viewModel.checkAllServers() }
                        } label: {
                            if viewModel.isChecking {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(viewModel.isChecking)
                    }
                }
            }
            .sheet(isPresented: $showingAddServer) {
                AddServerView { newServer in
                    viewModel.addServer(newServer)
                }
            }
            .sheet(item: $editingServer) { server in
                AddServerView(existingServer: server) { updatedServer in
                    viewModel.updateServer(updatedServer)
                }
            }
            .refreshable {
                await viewModel.checkAllServers()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("尚未添加伺服器")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("點擊右上角 + 添加要監控的伺服器")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Button {
                showingAddServer = true
            } label: {
                Label("添加伺服器", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var serverListView: some View {
        List {
            ForEach(viewModel.servers) { server in
                ServerRowView(server: server) {
                    Task { await viewModel.checkServer(server) }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editingServer = server
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.deleteServer(server)
                    } label: {
                        Label("刪除", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        Task { await viewModel.checkServer(server) }
                    } label: {
                        Label("檢查", systemImage: "arrow.clockwise")
                    }
                    .tint(.blue)
                }
            }
            .onMove { from, to in
                viewModel.moveServer(from: from, to: to)
            }

            if let lastChecked = viewModel.servers.compactMap({ $0.lastChecked }).max() {
                Section {
                    Text("最後檢查: \(lastChecked.formatted(date: .abbreviated, time: .standard))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    ContentView()
}
