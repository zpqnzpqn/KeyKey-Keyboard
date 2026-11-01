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

    /// 強制執行硬體領域不變量與邊界清洗 (防範 VULN-05 外部設定檔參數越界)
    public func sanitized() -> KeyKeyProfile {
        var copy = self
        copy.key1Config.layer = 0
        copy.key1Config.keyIndex = 0
        copy.key2Config.layer = 0
        copy.key2Config.keyIndex = 1

        copy.key1Macro = Self.sanitizeMacro(copy.key1Macro, expectedIndex: 0)
        copy.key2Macro = Self.sanitizeMacro(copy.key2Macro, expectedIndex: 1)

        copy.rgbConfig.hue = min(max(copy.rgbConfig.hue, 0.0), 359.0)
        copy.rgbConfig.saturation = min(max(copy.rgbConfig.saturation, 0.0), 100.0)
        copy.rgbConfig.lightness = min(max(copy.rgbConfig.lightness, 0.0), 100.0)
        return copy
    }

    private static func sanitizeMacro(_ macro: MacroConfig, expectedIndex: Int) -> MacroConfig {
        var m = macro
        m.layer = 0
        m.keyIndex = expectedIndex
        if m.type != .keyboard && m.type != .mouse {
            m.type = .keyboard
        }
        if case .count(let c) = m.loopMode {
            m.loopMode = .count(min(max(c, 1), 250))
        }
        let maxSteps = m.type == .mouse ? 8 : 14
        if m.steps.count > maxSteps {
            m.steps = Array(m.steps.prefix(maxSteps))
        }
        m.steps = m.steps.map { step in
            var s = step
            s.pressDuration = min(max(s.pressDuration, 1), 250)
            s.delayAfter = min(max(s.delayAfter, 1), 250)
            return s
        }
        return m
    }
}

/// 高風險巨集靜態安全檢測器 (防範 VULN-02 惡意快捷鍵注入與高速無限迴圈阻斷)
public enum MacroSafetyAuditor {
    public static func inspect(macro: MacroConfig) -> [String] {
        var warnings: [String] = []
        guard !macro.steps.isEmpty else { return warnings }

        // 1. 檢查是否包含系統命令啟動組合鍵 (Cmd+Space Spotlight / Win+R 執行視窗)
        if macro.type == .keyboard {
            for (idx, step) in macro.steps.enumerated() {
                let hasGUI = step.modifiers.contains(.leftGUI) || step.modifiers.contains(.rightGUI)
                if hasGUI && step.keyCode == 44 {
                    warnings.append("步驟 #\(idx + 1) 包含「Cmd/Win + Space」（可能開啟系統搜尋或執行終端指令）。")
                } else if hasGUI && step.keyCode == 21 {
                    warnings.append("步驟 #\(idx + 1) 包含「Cmd/Win + R」（可能觸發系統執行視窗）。")
                }
            }
        }

        // 2. 檢查是否為極短延遲 (<= 20ms) 的無限循環或按住循環，可能導致主機輸入佇列洪水鎖死
        let isContinuousLoop = (macro.loopMode == .infinite || macro.loopMode == .holdToLoop)
        if isContinuousLoop {
            let totalTicks = macro.steps.reduce(0) { $0 + $1.pressDuration + $1.delayAfter }
            if totalTicks <= 2 {
                warnings.append("此巨集設定為「\(macro.loopMode == .infinite ? "無限循環" : "按住循環")」且總週期僅 \(totalTicks * 10)ms，極高速連發可能導致電腦鍵鼠輸入暫時無回應。")
            }
        }

        return warnings
    }

    public static func inspect(profile: KeyKeyProfile) -> [String] {
        var results: [String] = []
        for w in inspect(macro: profile.key1Macro) {
            results.append("[按鍵 1 巨集] \(w)")
        }
        for w in inspect(macro: profile.key2Macro) {
            results.append("[按鍵 2 巨集] \(w)")
        }
        return results
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
        return try encoder.encode(profile.sanitized())
    }

    /// 從 JSON Data 匯入設定檔 (自動執行邊界消毒)
    public func importProfile(from data: Data) throws -> KeyKeyProfile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(KeyKeyProfile.self, from: data)
        return decoded.sanitized()
    }
}
