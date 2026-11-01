import Foundation

/// 完整設定檔封裝
public struct KeyKeyProfile: Codable, Identifiable {
    public var id = UUID()
    public var profileName: String
    public var createdAt: Date
    public var key1Config: KeyConfig
    public var key2Config: KeyConfig
    public var key1Macro: MacroConfig
    public var key2Macro: MacroConfig
    public var rgbConfig: RGBConfig

    public init(profileName: String = "預設設定檔", createdAt: Date = Date(), key1Config: KeyConfig, key2Config: KeyConfig, key1Macro: MacroConfig, key2Macro: MacroConfig, rgbConfig: RGBConfig) {
        self.profileName = profileName
        self.createdAt = createdAt
        self.key1Config = key1Config
        self.key2Config = key2Config
        self.key1Macro = key1Macro
        self.key2Macro = key2Macro
        self.rgbConfig = rgbConfig
    }
}

/// 設定檔匯入與匯出管理員
public final class ProfileManager {
    public static let shared = ProfileManager()

    /// 匯出設定檔為 JSON Data
    public func exportProfile(_ profile: KeyKeyProfile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(profile)
    }

    /// 從 JSON Data 匯入設定檔
    public func importProfile(from data: Data) throws -> KeyKeyProfile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(KeyKeyProfile.self, from: data)
    }
}
