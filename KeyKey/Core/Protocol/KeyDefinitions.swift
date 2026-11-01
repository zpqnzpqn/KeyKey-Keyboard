import Foundation

/// USB HID 鍵盤按鍵定義與對應
public struct KeyItem: Identifiable, Hashable, Codable {
    public let id: Int
    public let code: UInt8
    public let name: String
    public let displayLabel: String
    public let category: KeyCategory

    public init(code: UInt8, name: String, displayLabel: String, category: KeyCategory = .standard) {
        self.id = Int(code)
        self.code = code
        self.name = name
        self.displayLabel = displayLabel
        self.category = category
    }
}

public enum KeyCategory: String, CaseIterable, Codable {
    case standard = "鍵盤按鍵"
    case modifier = "修飾鍵"
    case media = "多媒體"
    case mouse = "滑鼠動作"
}

/// 修飾鍵遮罩旗標
public struct ModifierMask: OptionSet, Codable, Hashable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let leftCtrl   = ModifierMask(rawValue: 1 << 0) // 1
    public static let leftShift  = ModifierMask(rawValue: 1 << 1) // 2
    public static let leftAlt    = ModifierMask(rawValue: 1 << 2) // 4 (Option)
    public static let leftGUI    = ModifierMask(rawValue: 1 << 3) // 8 (Command / Win)
    public static let rightCtrl  = ModifierMask(rawValue: 1 << 4) // 16
    public static let rightShift = ModifierMask(rawValue: 1 << 5) // 32
    public static let rightAlt   = ModifierMask(rawValue: 1 << 6) // 64 (Option)
    public static let rightGUI   = ModifierMask(rawValue: 1 << 7) // 128 (Command / Win)

    public var displayString: String {
        var parts: [String] = []
        if contains(.leftCtrl) || contains(.rightCtrl) { parts.append("Ctrl") }
        if contains(.leftShift) || contains(.rightShift) { parts.append("Shift") }
        if contains(.leftAlt) || contains(.rightAlt) { parts.append("Option") }
        if contains(.leftGUI) || contains(.rightGUI) { parts.append("Cmd") }
        return parts.joined(separator: " + ")
    }
}

/// 滑鼠動作遮罩
public struct MouseButtonMask: OptionSet, Codable, Hashable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let left     = MouseButtonMask(rawValue: 1 << 0) // 1
    public static let right    = MouseButtonMask(rawValue: 1 << 1) // 2
    public static let middle   = MouseButtonMask(rawValue: 1 << 2) // 4
    public static let sideDown = MouseButtonMask(rawValue: 1 << 3) // 8
    public static let sideUp   = MouseButtonMask(rawValue: 1 << 4) // 16
}

/// 鍵位常數庫
public enum KeyDefinitions {
    public static let standardKeys: [KeyItem] = [
        // 第一排 F 鍵
        KeyItem(code: 41, name: "Esc", displayLabel: "Esc"),
        KeyItem(code: 58, name: "F1", displayLabel: "F1"),
        KeyItem(code: 59, name: "F2", displayLabel: "F2"),
        KeyItem(code: 60, name: "F3", displayLabel: "F3"),
        KeyItem(code: 61, name: "F4", displayLabel: "F4"),
        KeyItem(code: 62, name: "F5", displayLabel: "F5"),
        KeyItem(code: 63, name: "F6", displayLabel: "F6"),
        KeyItem(code: 64, name: "F7", displayLabel: "F7"),
        KeyItem(code: 65, name: "F8", displayLabel: "F8"),
        KeyItem(code: 66, name: "F9", displayLabel: "F9"),
        KeyItem(code: 67, name: "F10", displayLabel: "F10"),
        KeyItem(code: 68, name: "F11", displayLabel: "F11"),
        KeyItem(code: 69, name: "F12", displayLabel: "F12"),

        // 數字行
        KeyItem(code: 53, name: "`", displayLabel: "~\n`"),
        KeyItem(code: 30, name: "1", displayLabel: "!\n1"),
        KeyItem(code: 31, name: "2", displayLabel: "@\n2"),
        KeyItem(code: 32, name: "3", displayLabel: "#\n3"),
        KeyItem(code: 33, name: "4", displayLabel: "$\n4"),
        KeyItem(code: 34, name: "5", displayLabel: "%\n5"),
        KeyItem(code: 35, name: "6", displayLabel: "^\n6"),
        KeyItem(code: 36, name: "7", displayLabel: "&\n7"),
        KeyItem(code: 37, name: "8", displayLabel: "*\n8"),
        KeyItem(code: 38, name: "9", displayLabel: "(\n9"),
        KeyItem(code: 39, name: "0", displayLabel: ")\n0"),
        KeyItem(code: 45, name: "-", displayLabel: "_\n-"),
        KeyItem(code: 46, name: "=", displayLabel: "+\n="),
        KeyItem(code: 42, name: "Backspace", displayLabel: "⌫ 刪除"),

        // QWERTY 行
        KeyItem(code: 43, name: "Tab", displayLabel: "Tab ⇥"),
        KeyItem(code: 20, name: "Q", displayLabel: "Q"),
        KeyItem(code: 26, name: "W", displayLabel: "W"),
        KeyItem(code: 8,  name: "E", displayLabel: "E"),
        KeyItem(code: 21, name: "R", displayLabel: "R"),
        KeyItem(code: 23, name: "T", displayLabel: "T"),
        KeyItem(code: 28, name: "Y", displayLabel: "Y"),
        KeyItem(code: 24, name: "U", displayLabel: "U"),
        KeyItem(code: 12, name: "I", displayLabel: "I"),
        KeyItem(code: 18, name: "O", displayLabel: "O"),
        KeyItem(code: 19, name: "P", displayLabel: "P"),
        KeyItem(code: 47, name: "[", displayLabel: "{\n["),
        KeyItem(code: 48, name: "]", displayLabel: "}\n]"),
        KeyItem(code: 49, name: "\\", displayLabel: "|\n\\"),

        // ASDF 行
        KeyItem(code: 57, name: "Caps Lock", displayLabel: "Caps ⇪"),
        KeyItem(code: 4,  name: "A", displayLabel: "A"),
        KeyItem(code: 22, name: "S", displayLabel: "S"),
        KeyItem(code: 7,  name: "D", displayLabel: "D"),
        KeyItem(code: 9,  name: "F", displayLabel: "F"),
        KeyItem(code: 10, name: "G", displayLabel: "G"),
        KeyItem(code: 11, name: "H", displayLabel: "H"),
        KeyItem(code: 13, name: "J", displayLabel: "J"),
        KeyItem(code: 14, name: "K", displayLabel: "K"),
        KeyItem(code: 15, name: "L", displayLabel: "L"),
        KeyItem(code: 51, name: ";", displayLabel: ":\n;"),
        KeyItem(code: 52, name: "'", displayLabel: "\"\n'"),
        KeyItem(code: 40, name: "Enter", displayLabel: "Return ⏎"),

        // ZXCV 行
        KeyItem(code: 29, name: "Z", displayLabel: "Z"),
        KeyItem(code: 27, name: "X", displayLabel: "X"),
        KeyItem(code: 6,  name: "C", displayLabel: "C"),
        KeyItem(code: 25, name: "V", displayLabel: "V"),
        KeyItem(code: 5,  name: "B", displayLabel: "B"),
        KeyItem(code: 17, name: "N", displayLabel: "N"),
        KeyItem(code: 16, name: "M", displayLabel: "M"),
        KeyItem(code: 54, name: ",", displayLabel: "<\n,"),
        KeyItem(code: 55, name: ".", displayLabel: ">\n."),
        KeyItem(code: 56, name: "/", displayLabel: "?\n/"),

        // 底部與功能鍵
        KeyItem(code: 44, name: "Space", displayLabel: "空白鍵 (Space)"),
        KeyItem(code: 73, name: "Insert", displayLabel: "Insert"),
        KeyItem(code: 74, name: "Home", displayLabel: "Home"),
        KeyItem(code: 75, name: "PageUp", displayLabel: "Page Up ⇞"),
        KeyItem(code: 76, name: "Delete", displayLabel: "Delete ⌦"),
        KeyItem(code: 77, name: "End", displayLabel: "End"),
        KeyItem(code: 78, name: "PageDown", displayLabel: "Page Down ⇟"),

        // 方向鍵
        KeyItem(code: 82, name: "Up", displayLabel: "↑ 上"),
        KeyItem(code: 81, name: "Down", displayLabel: "↓ 下"),
        KeyItem(code: 80, name: "Left", displayLabel: "← 左"),
        KeyItem(code: 79, name: "Right", displayLabel: "→ 右")
    ]

    /// 多媒體消費控制鍵 (Consumer Controls)
    public static let mediaKeys: [KeyItem] = [
        KeyItem(code: 226, name: "Mute", displayLabel: "靜音", category: .media),
        KeyItem(code: 234, name: "Volume-", displayLabel: "音量 -", category: .media),
        KeyItem(code: 233, name: "Volume+", displayLabel: "音量 +", category: .media),
        KeyItem(code: 205, name: "PlayPause", displayLabel: "播放 / 暫停", category: .media),
        KeyItem(code: 182, name: "PrevTrack", displayLabel: "上一曲", category: .media),
        KeyItem(code: 181, name: "NextTrack", displayLabel: "下一曲", category: .media),
        KeyItem(code: 112, name: "Brightness-", displayLabel: "螢幕亮度 -", category: .media),
        KeyItem(code: 111, name: "Brightness+", displayLabel: "螢幕亮度 +", category: .media),
        KeyItem(code: 146, name: "Calculator", displayLabel: "計算機", category: .media),
        KeyItem(code: 35,  name: "BrowserHome", displayLabel: "瀏覽器首頁", category: .media),
        KeyItem(code: 64,  name: "Menu", displayLabel: "選單", category: .media),
        KeyItem(code: 36,  name: "BrowserBack", displayLabel: "上一頁 / 返回", category: .media)
    ]

    /// 根據鍵碼查詢名稱
    public static func name(for code: UInt8, type: UInt8) -> String {
        if type == 2 {
            return mediaKeys.first(where: { $0.code == code })?.displayLabel ?? "多媒體鍵 (\(code))"
        } else if type == 3 {
            return mouseName(for: code)
        }
        return standardKeys.first(where: { $0.code == code })?.displayLabel ?? "鍵碼 (\(code))"
    }

    private static func mouseName(for code: UInt8) -> String {
        switch code {
        case 1: return "滑鼠左鍵"
        case 2: return "滑鼠右鍵"
        case 4: return "滑鼠中鍵"
        case 8: return "滑鼠下側鍵"
        case 16: return "滑鼠上側鍵"
        default: return "滑鼠按鍵 (\(code))"
        }
    }
}
