import SwiftUI

/// 按下觸發燈效模式
public enum RGBTriggerMode: UInt8, CaseIterable, Identifiable, Codable {
    case luckyColor1 = 1
    case customColor = 2
    case luckyColor2 = 3

    public var id: UInt8 { rawValue }

    public var displayName: String {
        switch self {
        case .luckyColor1: return "幸運色 1"
        case .customColor: return "自訂顏色"
        case .luckyColor2: return "幸運色 2"
        }
    }
}

/// 常態小夜燈模式
public enum RGBNightlightMode: UInt8, CaseIterable, Identifiable, Codable {
    case customStatic = 1
    case customBreathing = 2
    case rainbow = 3

    public var id: UInt8 { rawValue }

    public var displayName: String {
        switch self {
        case .customStatic: return "指定色恆亮"
        case .customBreathing: return "指定色呼吸燈"
        case .rainbow: return "彩虹流光"
        }
    }
}

/// 綜合主燈光模式
public enum RGBMainMode: Int, CaseIterable, Identifiable, Codable {
    case trigger = 1       // 按下亮
    case nightlight = 2    // 小夜燈
    case speedTest = 3     // 測手速
    case lightsOff = 4     // 關燈

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .trigger: return "按下亮燈 (觸發模式)"
        case .nightlight: return "小夜燈模式"
        case .speedTest: return "手速測驗 (Speed Test)"
        case .lightsOff: return "關閉燈光"
        }
    }
}

/// RGB 燈光套用目標
public enum RGBTarget: String, CaseIterable, Identifiable, Codable {
    case all = "all"
    case key1 = "key1"
    case key2 = "key2"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .all: return "雙鍵同步 (套用至全部)"
        case .key1: return "僅按鍵 1 (LED 1)"
        case .key2: return "僅按鍵 2 (LED 2)"
        }
    }

    /// 硬體協定對應的 rgbIndex 陣列 (0 = Key 1 LED, 1 = Key 2 LED)
    public var hardwareIndices: [UInt8] {
        switch self {
        case .all: return [0, 1]
        case .key1: return [0]
        case .key2: return [1]
        }
    }
}

/// RGB 完整配置模型
public struct RGBConfig: Codable, Equatable {
    public var target: RGBTarget = .all
    public var mainMode: RGBMainMode = .nightlight
    public var triggerMode: RGBTriggerMode = .customColor
    public var nightlightMode: RGBNightlightMode = .rainbow
    public var hue: Double = 180.0       // 0 ~ 359
    public var saturation: Double = 80.0 // 0 ~ 100 (送出硬體時轉換為 0 ~ 255)
    public var lightness: Double = 50.0  // 0 ~ 100 (送出硬體時轉換為 0 ~ 255)

    public init(target: RGBTarget = .all, mainMode: RGBMainMode = .nightlight, triggerMode: RGBTriggerMode = .customColor, nightlightMode: RGBNightlightMode = .rainbow, hue: Double = 180.0, saturation: Double = 80.0, lightness: Double = 50.0) {
        self.target = target
        self.mainMode = mainMode
        self.triggerMode = triggerMode
        self.nightlightMode = nightlightMode
        self.hue = hue
        self.saturation = saturation
        self.lightness = lightness
    }

    /// 轉成 SwiftUI Color
    public var swiftUIColor: Color {
        Color(hue: hue / 360.0, saturation: saturation / 100.0, brightness: lightness / 100.0)
    }

    /// 根據 SwiftUI Color 設定 HSL
    public mutating func setColor(_ color: Color) {
        // 使用 NSColor 取得 HSB
        if let nsColor = NSColor(color).usingColorSpace(.deviceRGB) {
            hue = Double(nsColor.hueComponent * 360.0)
            saturation = Double(nsColor.saturationComponent * 100.0)
            lightness = Double(nsColor.brightnessComponent * 100.0)
        }
    }
}
