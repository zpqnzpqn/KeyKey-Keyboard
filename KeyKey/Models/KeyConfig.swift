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
    public var codeHigh: UInt8 = 0 // Consumer 16-bit 高位元組
    public var mouseButtons: MouseButtonMask = .left
    public var mouseMoveX: Int8 = 0 // 游標 X 位移 (-127 ~ 127)
    public var mouseMoveY: Int8 = 0 // 游標 Y 位移 (-127 ~ 127)
    public var mouseWheel: Int8 = 0 // 滾輪刻度 (-127 ~ 127)
    public var customName: String = ""

    public init(
        layer: UInt8 = 0,
        keyIndex: Int,
        mode: KeyMode = .single,
        type: KeyType = .keyboard,
        modifiers: ModifierMask = [],
        keyCode: UInt8 = 4,
        codeHigh: UInt8 = 0,
        mouseButtons: MouseButtonMask = .left,
        mouseMoveX: Int8 = 0,
        mouseMoveY: Int8 = 0,
        mouseWheel: Int8 = 0,
        customName: String = ""
    ) {
        self.layer = layer
        self.keyIndex = keyIndex
        self.mode = mode
        self.type = type
        self.modifiers = modifiers
        self.keyCode = keyCode
        self.codeHigh = codeHigh
        self.mouseButtons = mouseButtons
        self.mouseMoveX = mouseMoveX
        self.mouseMoveY = mouseMoveY
        self.mouseWheel = mouseWheel
        self.customName = customName
    }

    /// 取得摘要文字顯示
    public var summaryString: String {
        if mode == .macro {
            return "巨集模式 (Macro)"
        }
        switch type {
        case .keyboard:
            var desc = ""
            if !modifiers.isEmpty {
                desc += modifiers.displayString + " + "
            }
            desc += KeyDefinitions.name(for: keyCode, type: type.rawValue)
            return desc
        case .consumer:
            return KeyDefinitions.name(for: keyCode, codeHigh: codeHigh, type: type.rawValue)
        case .mouse:
            var parts: [String] = []
            if !mouseButtons.isEmpty {
                parts.append(mouseButtons.displayString)
            }
            if mouseMoveX != 0 || mouseMoveY != 0 {
                parts.append("游標(\(mouseMoveX),\(mouseMoveY))")
            }
            if mouseWheel != 0 {
                parts.append("滾輪(\(mouseWheel > 0 ? "+\(mouseWheel)" : "\(mouseWheel)"))")
            }
            return parts.isEmpty ? "滑鼠動作" : parts.joined(separator: " ")
        }
    }
}
