import SwiftUI

struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: AppSettings

    @State private var name: String = ""
    @State private var host: String = ""
    @State private var portString: String = ""
    @State private var checkType: CheckType = .http
    @State private var showingError = false
    @State private var errorMessage = ""

    let existingServer: ServerEntry?
    let onSave: (ServerEntry) -> Void

    init(existingServer: ServerEntry? = nil, onSave: @escaping (ServerEntry) -> Void) {
        self.existingServer = existingServer
        self.onSave = onSave
    }

    private var s: L10nStrings { settings.strings }
    var isEditing: Bool { existingServer != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(s.basicInfo) {
                    TextField(s.nameLabel, text: $name)
                        .textContentType(.name)

                    TextField(s.hostPlaceholder, text: $host)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.webSearch)
                }

                Section(s.checkMethod) {
                    Picker(s.typeLabel, selection: $checkType) {
                        ForEach(CheckType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    if checkType == .tcp {
                        TextField(s.portLabel, text: $portString)
                            .keyboardType(.numberPad)
                    }

                    if checkType == .http {
                        TextField(s.portOptional, text: $portString)
                            .keyboardType(.numberPad)
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        switch checkType {
                        case .http:
                            Text(s.httpDescription)
                        case .tcp:
                            Text(s.tcpDescription)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(isEditing ? s.editServer : s.addServer)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(s.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? s.save : s.add) {
                        saveServer()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || host.isEmpty)
                }
            }
            .alert(s.error, isPresented: $showingError) {
                Button(s.ok) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if let server = existingServer {
                    name = server.name
                    host = server.host
                    portString = server.port.map(String.init) ?? ""
                    checkType = server.checkType
                }
            }
        }
    }

    private func saveServer() {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = s.nameRequired
            showingError = true
            return
        }

        guard !trimmedHost.isEmpty else {
            errorMessage = s.hostRequired
            showingError = true
            return
        }

        var port: Int? = nil
        if !portString.isEmpty {
            guard let p = Int(portString), p > 0, p <= 65535 else {
                errorMessage = s.invalidPort
                showingError = true
                return
            }
            port = p
        }

        if checkType == .tcp && port == nil {
            errorMessage = s.tcpPortRequired
            showingError = true
            return
        }

        var server = existingServer ?? ServerEntry(name: trimmedName, host: trimmedHost)
        server.name = trimmedName
        server.host = trimmedHost
        server.port = port
        server.checkType = checkType

        onSave(server)
        dismiss()
    }
}

#Preview {
    AddServerView { server in
        print(server)
    }
    .environmentObject(AppSettings.shared)
}
