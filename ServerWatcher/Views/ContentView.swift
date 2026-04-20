import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ServerViewModel()
    @EnvironmentObject var settings: AppSettings
    @State private var showingAddServer = false
    @State private var editingServer: ServerEntry? = nil
    @State private var showingSettings = false

    private var s: L10nStrings { settings.strings }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.servers.isEmpty {
                    emptyStateView
                } else {
                    serverListView
                }
            }
            .navigationTitle(s.appName)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 20) {
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
                            .padding(.leading, 8)
                        }
                        Button {
                            showingAddServer = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .padding(.trailing, 8)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingAddServer) {
                AddServerView { newServer in
                    viewModel.addServer(newServer)
                }
                .environmentObject(settings)
            }
            .sheet(item: $editingServer) { server in
                AddServerView(existingServer: server) { updatedServer in
                    viewModel.updateServer(updatedServer)
                }
                .environmentObject(settings)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(settings)
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
            Text(s.noServersTitle)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(s.noServersSubtitle)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Button {
                showingAddServer = true
            } label: {
                Label(s.addServer, systemImage: "plus")
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
                        Label(s.delete, systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        Task { await viewModel.checkServer(server) }
                    } label: {
                        Label(s.check, systemImage: "arrow.clockwise")
                    }
                    .tint(.blue)
                }
            }
            .onMove { from, to in
                viewModel.moveServer(from: from, to: to)
            }

            if let lastChecked = viewModel.servers.compactMap({ $0.lastChecked }).max() {
                Section {
                    Text("\(s.lastCheckedPrefix): \(lastChecked.formatted(date: .abbreviated, time: .standard))")
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
        .environmentObject(AppSettings.shared)
}
