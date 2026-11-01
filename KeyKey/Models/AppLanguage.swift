import Foundation

/// 支援的使用者介面語系
public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case traditionalChinese = "zh-Hant"
    case english = "en"
    case japanese = "ja"
    case spanish = "es"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .traditionalChinese:
            return "繁體中文 (台灣)"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .spanish:
            return "Español"
        }
    }

    public var locale: Locale {
        Locale(identifier: rawValue)
    }
}
