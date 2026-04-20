import SwiftUI

struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss

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

    var isEditing: Bool { existingServer != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本資訊") {
                    TextField("名稱", text: $name)
                        .textContentType(.name)

                    TextField("主機位址 (URL / IP)", text: $host)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }

                Section("檢查方式") {
                    Picker("類型", selection: $checkType) {
                        ForEach(CheckType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    if checkType == .tcp {
                        TextField("端口 (Port)", text: $portString)
                            .keyboardType(.numberPad)
                    }

                    if checkType == .http {
                        TextField("端口 (可選)", text: $portString)
                            .keyboardType(.numberPad)
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        switch checkType {
                        case .http:
                            Text("將發送 HTTP HEAD 請求來檢查連接狀態")
                        case .tcp:
                            Text("將嘗試建立 TCP 連接來檢查端口是否開啟")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(isEditing ? "編輯伺服器" : "添加伺服器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "儲存" : "添加") {
                        saveServer()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || host.isEmpty)
                }
            }
            .alert("錯誤", isPresented: $showingError) {
                Button("確定") {}
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
            errorMessage = "請輸入伺服器名稱"
            showingError = true
            return
        }

        guard !trimmedHost.isEmpty else {
            errorMessage = "請輸入主機位址"
            showingError = true
            return
        }

        var port: Int? = nil
        if !portString.isEmpty {
            guard let p = Int(portString), p > 0, p <= 65535 else {
                errorMessage = "端口必須是 1-65535 之間的數字"
                showingError = true
                return
            }
            port = p
        }

        if checkType == .tcp && port == nil {
            errorMessage = "TCP 檢查需要指定端口"
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
}
