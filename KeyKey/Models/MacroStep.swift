import Foundation

/// 巨集循環模式
public enum MacroLoopMode: Codable, Equatable {
    case count(Int)
    case infinite
    case holdToLoop

    public var rawValue: UInt8 {
        switch self {
        case .count(let c):
            return UInt8(clamping: c)
        case .infinite:
            return 255
        case .holdToLoop:
            return 254
        }
    }

    public init(rawValue: UInt8) {
        if rawValue == 255 {
            self = .infinite
        } else if rawValue == 254 {
            self = .holdToLoop
        } else {
            self = .count(Int(rawValue))
        }
    }
}

/// 巨集單一步驟動作
public struct MacroStep: Identifiable, Codable, Equatable {
    public var id = UUID()
    // 鍵盤巨集欄位
    public var modifiers: ModifierMask = []
    public var keyCode: UInt8 = 4 // 'A'
    // 滑鼠巨集欄位
    public var mouseButtons: MouseButtonMask = .left
    public var mouseMoveX: Int8 = 0
    public var mouseMoveY: Int8 = 0
    public var mouseWheel: Int8 = 0
    // 時間欄位 (單位: *10ms, 範圍 1 ~ 250)
    public var pressDuration: Int = 5 // *10ms = 50ms
    public var delayAfter: Int = 5    // *10ms = 50ms

    public init(
        id: UUID = UUID(),
        modifiers: ModifierMask = [],
        keyCode: UInt8 = 4,
        mouseButtons: MouseButtonMask = .left,
        mouseMoveX: Int8 = 0,
        mouseMoveY: Int8 = 0,
        mouseWheel: Int8 = 0,
        pressDuration: Int = 5,
        delayAfter: Int = 5
    ) {
        self.id = id
        self.modifiers = modifiers
        self.keyCode = keyCode
        self.mouseButtons = mouseButtons
        self.mouseMoveX = mouseMoveX
        self.mouseMoveY = mouseMoveY
        self.mouseWheel = mouseWheel
        self.pressDuration = pressDuration
        self.delayAfter = delayAfter
    }

    public var displayLabel: String {
        displayLabel(for: .keyboard)
    }

    public func displayLabel(for macroType: KeyType) -> String {
        if macroType == .mouse {
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
            return parts.isEmpty ? "滑鼠等待" : parts.joined(separator: " · ")
        }
        var str = ""
        if !modifiers.isEmpty {
            str += modifiers.displayString + " + "
        }
        str += KeyDefinitions.name(for: keyCode, type: 1)
        return str
    }
}

/// 巨集完整設定
public struct MacroConfig: Identifiable, Codable, Equatable {
    public var id: Int { keyIndex }
    public var layer: UInt8 = 0
    public var keyIndex: Int // 0 or 1
    public var type: KeyType = .keyboard // .keyboard or .mouse
    public var loopMode: MacroLoopMode = .infinite
    public var steps: [MacroStep] = []

    public init(layer: UInt8 = 0, keyIndex: Int, type: KeyType = .keyboard, loopMode: MacroLoopMode = .infinite, steps: [MacroStep] = []) {
        self.layer = layer
        self.keyIndex = keyIndex
        self.type = type
        self.loopMode = loopMode
        self.steps = steps
    }
}
