import Foundation

// MARK: - AppLanguage

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english            = "en"
    case traditionalChinese = "zh-Hant"
    case simplifiedChinese  = "zh-Hans"
    case japanese           = "ja"
    case korean             = "ko"
    case french             = "fr"
    case german             = "de"
    case spanish            = "es"
    case portuguese         = "pt"
    case italian            = "it"
    case dutch              = "nl"
    case russian            = "ru"
    case arabic             = "ar"
    case thai               = "th"
    case vietnamese         = "vi"
    case indonesian         = "id"
    case polish             = "pl"
    case turkish            = "tr"
    case ukrainian          = "uk"
    case hindi              = "hi"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .english:            return "English"
        case .traditionalChinese: return "繁體中文"
        case .simplifiedChinese:  return "简体中文"
        case .japanese:           return "日本語"
        case .korean:             return "한국어"
        case .french:             return "Français"
        case .german:             return "Deutsch"
        case .spanish:            return "Español"
        case .portuguese:         return "Português"
        case .italian:            return "Italiano"
        case .dutch:              return "Nederlands"
        case .russian:            return "Русский"
        case .arabic:             return "العربية"
        case .thai:               return "ภาษาไทย"
        case .vietnamese:         return "Tiếng Việt"
        case .indonesian:         return "Bahasa Indonesia"
        case .polish:             return "Polski"
        case .turkish:            return "Türkçe"
        case .ukrainian:          return "Українська"
        case .hindi:              return "हिन्दी"
        }
    }
}

// MARK: - RefreshInterval

enum RefreshInterval: Int, CaseIterable, Identifiable {
    case sec30 = 30
    case min1  = 60
    case min3  = 180
    case min5  = 300
    case min10 = 600
    case min30 = 1800
    case never = 0

    var id: Int { rawValue }

    func displayName(using s: L10nStrings) -> String {
        switch self {
        case .sec30:  return s.sec30
        case .min1:   return s.min1
        case .min3:   return s.min3
        case .min5:   return s.min5
        case .min10:  return s.min10
        case .min30:  return s.min30
        case .never:  return s.never
        }
    }
}

// MARK: - AppSettings

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let suite     = "group.com.serverwatcher.shared"
    private let langKey   = "app_language"
    private let riKey     = "refresh_interval"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: suite) ?? .standard
    }

    var language: AppLanguage {
        get {
            guard let raw = defaults.string(forKey: langKey),
                  let lang = AppLanguage(rawValue: raw) else { return .english }
            return lang
        }
        set {
            objectWillChange.send()
            defaults.set(newValue.rawValue, forKey: langKey)
        }
    }

    var refreshInterval: RefreshInterval {
        get {
            guard defaults.object(forKey: riKey) != nil else { return .min1 }
            return RefreshInterval(rawValue: defaults.integer(forKey: riKey)) ?? .min1
        }
        set {
            objectWillChange.send()
            defaults.set(newValue.rawValue, forKey: riKey)
        }
    }

    var strings: L10nStrings { L10n.strings(for: language) }
}
