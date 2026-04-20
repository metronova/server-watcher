import SwiftUI
import WidgetKit

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

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
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings.shared)
}
