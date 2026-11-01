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
    public var modifiers: ModifierMask = []
    public var keyCode: UInt8 = 4 // 'A'
    public var pressDuration: Int = 5 // *10ms = 50ms
    public var delayAfter: Int = 5    // *10ms = 50ms

    public init(id: UUID = UUID(), modifiers: ModifierMask = [], keyCode: UInt8 = 4, pressDuration: Int = 5, delayAfter: Int = 5) {
        self.id = id
        self.modifiers = modifiers
        self.keyCode = keyCode
        self.pressDuration = pressDuration
        self.delayAfter = delayAfter
    }

    public var displayLabel: String {
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
