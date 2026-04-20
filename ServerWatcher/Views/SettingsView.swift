import SwiftUI
import WidgetKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var viewModel: ServerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingExporter = false
    @State private var exportDocument: ServerListDocument?
    @State private var showingImporter = false
    @State private var pendingImportData: Data?
    @State private var showingImportChoice = false
    @State private var showingImportSuccess = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""

    private var s: L10nStrings { settings.strings }

    var body: some View {
        NavigationStack {
            Form {
                Section(s.general) {
                    // Language picker
                    Picker(s.language, selection: Binding(
                        get: { settings.language },
                        set: { newLang in
                            settings.language = newLang
                            WidgetCenter.shared.reloadAllTimelines()
                        }
                    )) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.nativeName).tag(lang)
                        }
                    }

                    // Refresh interval picker
                    Picker(s.refreshInterval, selection: Binding(
                        get: { settings.refreshInterval },
                        set: { newInterval in
                            settings.refreshInterval = newInterval
                        }
                    )) {
                        ForEach(RefreshInterval.allCases) { interval in
                            Text(interval.displayName(using: s)).tag(interval)
                        }
                    }
                }

                Section(s.dataSection) {
                    Button {
                        if let data = try? viewModel.exportData() {
                            exportDocument = ServerListDocument(data: data)
                            showingExporter = true
                        }
                    } label: {
                        Label(s.exportServers, systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showingImporter = true
                    } label: {
                        Label(s.importServers, systemImage: "square.and.arrow.down")
                    }
                }

                Section(s.about) {
                    HStack {
                        Text(s.version)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(s.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(s.ok) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "servers"
            ) { _ in }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    do {
                        let data = try Data(contentsOf: url)
                        // Validate it's decodable before showing the choice
                        _ = try JSONDecoder().decode([ServerEntry].self, from: data)
                        pendingImportData = data
                        showingImportChoice = true
                    } catch {
                        importErrorMessage = error.localizedDescription
                        showingImportError = true
                    }
                case .failure(let error):
                    importErrorMessage = error.localizedDescription
                    showingImportError = true
                }
            }
            .confirmationDialog(
                s.importChoiceTitle,
                isPresented: $showingImportChoice,
                titleVisibility: .visible
            ) {
                Button(s.importMerge) {
                    if let data = pendingImportData {
                        try? viewModel.importServers(from: data, merge: true)
                        showingImportSuccess = true
                    }
                }
                Button(s.importReplace, role: .destructive) {
                    if let data = pendingImportData {
                        try? viewModel.importServers(from: data, merge: false)
                        showingImportSuccess = true
                    }
                }
                Button(s.cancel, role: .cancel) {}
            } message: {
                Text(s.importChoiceMessage)
            }
            .alert(s.importSuccess, isPresented: $showingImportSuccess) {
                Button(s.ok, role: .cancel) {}
            }
            .alert(s.importFailed, isPresented: $showingImportError) {
                Button(s.ok, role: .cancel) {}
            } message: {
                Text(importErrorMessage)
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: ServerViewModel())
        .environmentObject(AppSettings.shared)
}
