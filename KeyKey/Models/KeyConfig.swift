import Foundation

/// 按鍵運作模式
public enum KeyMode: UInt8, Codable {
    case single = 1
    case macro = 2
}

/// 按鍵硬體類型
public enum KeyType: UInt8, Codable {
    case keyboard = 1
    case consumer = 2
    case mouse = 3
}

/// 單一按鍵配置模型
public struct KeyConfig: Identifiable, Codable, Equatable {
    public var id: Int { keyIndex }
    public var layer: UInt8 = 0
    public var keyIndex: Int // 0: Key 1, 1: Key 2
    public var mode: KeyMode = .single
    public var type: KeyType = .keyboard
    public var modifiers: ModifierMask = []
    public var keyCode: UInt8 = 4 // 預設 'A' (Usage 4)
    public var customName: String = ""

    public init(layer: UInt8 = 0, keyIndex: Int, mode: KeyMode = .single, type: KeyType = .keyboard, modifiers: ModifierMask = [], keyCode: UInt8 = 4, customName: String = "") {
        self.layer = layer
        self.keyIndex = keyIndex
        self.mode = mode
        self.type = type
        self.modifiers = modifiers
        self.keyCode = keyCode
        self.customName = customName
    }

    /// 取得摘要文字顯示
    public var summaryString: String {
        if mode == .macro {
            return "巨集模式 (Macro)"
        }
        var desc = ""
        if !modifiers.isEmpty {
            desc += modifiers.displayString + " + "
        }
        desc += KeyDefinitions.name(for: keyCode, type: type.rawValue)
        return desc
    }
}
