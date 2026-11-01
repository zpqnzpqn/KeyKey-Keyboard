import Foundation

/// USB HID 鍵盤按鍵定義與對應
public struct KeyItem: Identifiable, Hashable, Codable {
    public let id: Int
    public let code: UInt8
    public let codeHigh: UInt8
    public let name: String
    public let displayLabel: String
    public let category: KeyCategory

    public init(code: UInt8, codeHigh: UInt8 = 0, name: String, displayLabel: String, category: KeyCategory = .standard) {
        self.id = (Int(codeHigh) << 8) | Int(code)
        self.code = code
        self.codeHigh = codeHigh
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

    public var displayString: String {
        var parts: [String] = []
        if contains(.left) { parts.append("左鍵") }
        if contains(.right) { parts.append("右鍵") }
        if contains(.middle) { parts.append("中鍵") }
        if contains(.sideDown) { parts.append("下側鍵") }
        if contains(.sideUp) { parts.append("上側鍵") }
        return parts.isEmpty ? "無按鍵" : "滑鼠" + parts.joined(separator: "+")
    }
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

    /// 多媒體消費控制鍵 (Consumer Controls: 16-bit HID Consumer Usage, 拆為 lowByte 與 highByte)
    public static let mediaKeys: [KeyItem] = [
        KeyItem(code: 226, codeHigh: 0, name: "Mute", displayLabel: "靜音", category: .media),
        KeyItem(code: 234, codeHigh: 0, name: "Volume-", displayLabel: "音量 -", category: .media),
        KeyItem(code: 233, codeHigh: 0, name: "Volume+", displayLabel: "音量 +", category: .media),
        KeyItem(code: 205, codeHigh: 0, name: "PlayPause", displayLabel: "播放 / 暫停", category: .media),
        KeyItem(code: 182, codeHigh: 0, name: "PrevTrack", displayLabel: "上一曲", category: .media),
        KeyItem(code: 181, codeHigh: 0, name: "NextTrack", displayLabel: "下一曲", category: .media),
        KeyItem(code: 112, codeHigh: 0, name: "Brightness-", displayLabel: "螢幕亮度 -", category: .media),
        KeyItem(code: 111, codeHigh: 0, name: "Brightness+", displayLabel: "螢幕亮度 +", category: .media),
        KeyItem(code: 146, codeHigh: 1, name: "Calculator", displayLabel: "計算機", category: .media),
        KeyItem(code: 35,  codeHigh: 2, name: "BrowserHome", displayLabel: "瀏覽器首頁", category: .media),
        KeyItem(code: 64,  codeHigh: 0, name: "Menu", displayLabel: "選單", category: .media),
        KeyItem(code: 36,  codeHigh: 2, name: "BrowserBack", displayLabel: "上一頁 / 返回", category: .media)
    ]

    /// 根據鍵碼查詢名稱
    public static func name(for code: UInt8, codeHigh: UInt8 = 0, type: UInt8) -> String {
        if type == 2 {
            if let matched = mediaKeys.first(where: { $0.code == code && $0.codeHigh == codeHigh }) {
                return matched.displayLabel
            }
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

    /// 將 macOS NSEvent Virtual KeyCode 轉換為 USB HID Usage ID
    public static func hidUsage(fromMacKeyCode macCode: UInt16) -> UInt8? {
        let map: [UInt16: UInt8] = [
            0x00: 4,  // A
            0x01: 22, // S
            0x02: 7,  // D
            0x03: 9,  // F
            0x04: 11, // H
            0x05: 10, // G
            0x06: 29, // Z
            0x07: 27, // X
            0x08: 6,  // C
            0x09: 25, // V
            0x0B: 5,  // B
            0x0C: 20, // Q
            0x0D: 26, // W
            0x0E: 8,  // E
            0x0F: 21, // R
            0x10: 28, // Y
            0x11: 23, // T
            0x12: 30, // 1
            0x13: 31, // 2
            0x14: 32, // 3
            0x15: 33, // 4
            0x16: 35, // 6
            0x17: 34, // 5
            0x18: 46, // =
            0x19: 38, // 9
            0x1A: 36, // 7
            0x1B: 45, // -
            0x1C: 37, // 8
            0x1D: 39, // 0
            0x1E: 48, // ]
            0x1F: 18, // O
            0x20: 24, // U
            0x21: 47, // [
            0x22: 12, // I
            0x23: 19, // P
            0x24: 40, // Return
            0x25: 15, // L
            0x26: 13, // J
            0x27: 52, // '
            0x28: 14, // K
            0x29: 51, // ;
            0x2A: 49, // \
            0x2B: 54, // ,
            0x2C: 56, // /
            0x2D: 17, // N
            0x2E: 16, // M
            0x2F: 55, // .
            0x30: 43, // Tab
            0x31: 44, // Space
            0x32: 53, // `
            0x33: 42, // Backspace
            0x35: 41, // Esc
            0x39: 57, // Caps Lock
            0x7A: 58, // F1
            0x78: 59, // F2
            0x63: 60, // F3
            0x76: 61, // F4
            0x60: 62, // F5
            0x61: 63, // F6
            0x62: 64, // F7
            0x64: 65, // F8
            0x65: 66, // F9
            0x6D: 67, // F10
            0x67: 68, // F11
            0x6F: 69, // F12
            0x72: 73, // Insert / Help
            0x73: 74, // Home
            0x74: 75, // PageUp
            0x75: 76, // Delete Forward
            0x77: 77, // End
            0x79: 78, // PageDown
            0x7B: 80, // Left
            0x7C: 79, // Right
            0x7D: 81, // Down
            0x7E: 82  // Up
        ]
        return map[macCode]
    }
}
