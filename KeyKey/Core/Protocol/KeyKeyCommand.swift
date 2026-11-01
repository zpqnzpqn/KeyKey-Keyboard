import Foundation

/// KeyKey 硬體通訊協定命令序列化工具
public struct KeyKeyCommand {
    // 協定索引定義
    public static let cmdTypeIndex = 1
    public static let keyLayerIndex = 2
    public static let keyIndex = 3
    public static let keyModeIndex = 4
    public static let keyTypeIndex = 5
    public static let keyModIndex = 6
    public static let keyCodeIndex = 7

    public static let macroTypeIndex = 5
    public static let macroLoopIndex = 6
    public static let macroStartIndex = 7

    public static let rgbIndex = 2
    public static let rgbHIndex = 3
    public static let rgbSIndex = 5
    public static let rgbLIndex = 6
    public static let rgbMode1Index = 7
    public static let rgbMode2Index = 8

    // 命令類型
    public static let cmdKey: UInt8 = 1
    public static let cmdRGB: UInt8 = 2
    public static let cmdFun: UInt8 = 3

    // MARK: - 單鍵封包 (65 位元組)
    public static func makeKeyPacket(config: KeyConfig) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 65)
        packet[0] = 0 // Report ID
        packet[cmdTypeIndex] = cmdKey
        packet[keyLayerIndex] = config.layer
        packet[keyIndex] = UInt8(config.keyIndex)
        packet[keyModeIndex] = config.mode.rawValue
        packet[keyTypeIndex] = config.type.rawValue
        packet[keyModIndex] = config.modifiers.rawValue
        packet[keyCodeIndex] = config.keyCode
        return packet
    }

    // MARK: - 巨集封包 (65 位元組)
    public static func makeMacroPacket(macro: MacroConfig) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 65)
        packet[0] = 0 // Report ID
        packet[cmdTypeIndex] = cmdKey
        packet[keyLayerIndex] = macro.layer
        packet[keyIndex] = UInt8(macro.keyIndex)
        packet[keyModeIndex] = 2 // 巨集模式
        packet[macroTypeIndex] = macro.type.rawValue
        packet[macroLoopIndex] = macro.loopMode.rawValue

        // 最多 14 個步驟，每步驟佔 4 位元組：[Mod, KeyCode, PressDuration, DelayAfter]
        let maxSteps = min(macro.steps.count, 14)
        for i in 0..<maxSteps {
            let step = macro.steps[i]
            let offset = macroStartIndex + (i * 4)
            packet[offset] = step.modifiers.rawValue
            packet[offset + 1] = step.keyCode
            packet[offset + 2] = UInt8(clamping: step.pressDuration)
            packet[offset + 3] = UInt8(clamping: step.delayAfter)
        }
        return packet
    }

    // MARK: - RGB 燈效封包 (17 位元組)
    public static func makeRGBPacket(config: RGBConfig, keyIndex: UInt8 = 255) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 17)
        packet[0] = 0 // Report ID
        packet[cmdTypeIndex] = cmdRGB
        packet[rgbIndex] = keyIndex // 255 代表全域

        let hueInt = UInt16(clamping: Int(config.hue))
        packet[rgbHIndex] = UInt8((hueInt >> 8) & 0xFF)
        packet[rgbHIndex + 1] = UInt8(hueInt & 0xFF)
        packet[rgbSIndex] = UInt8(clamping: Int(config.saturation))
        packet[rgbLIndex] = UInt8(clamping: Int(config.lightness))

        switch config.mainMode {
        case .trigger:
            packet[rgbMode1Index] = 1
            packet[rgbMode2Index] = config.triggerMode.rawValue
        case .nightlight:
            packet[rgbMode1Index] = 2
            packet[rgbMode2Index] = config.nightlightMode.rawValue
        case .speedTest:
            packet[rgbMode1Index] = 3
            packet[rgbMode2Index] = 0
        case .lightsOff:
            packet[rgbMode1Index] = 4
            packet[rgbMode2Index] = 0
        }
        return packet
    }

    // MARK: - 系統控制命令
    public static let enterIAP = [UInt8]([0, cmdFun, 1, 90, 0, 0, 0, 0, 0])
    public static let setUSBMode = [UInt8]([0, cmdFun, 2, 1, 0, 0, 0, 0, 0])
    public static let setBLEMode = [UInt8]([0, cmdFun, 2, 2, 0, 0, 0, 0, 0])
    public static let getVersion = [UInt8]([0, cmdFun, 4, 0, 0, 0, 0, 0, 0])
    public static let getBattery = [UInt8]([0, cmdFun, 5, 0, 0, 0, 0, 0, 0])
    public static let getMAC = [UInt8]([0, cmdFun, 6, 0, 0, 0, 0, 0, 0])
    public static let powerOnPair = [UInt8]([0, cmdFun, 7, 1, 0, 0, 0, 0, 0])
    public static let powerOnUnpair = [UInt8]([0, cmdFun, 7, 2, 0, 0, 0, 0, 0])

    // MARK: - 回應解析
    public static func parseVersionResponse(_ data: [UInt8]) -> String? {
        // 舊版判斷: ret[0] == CMD_TYPE_FUN (3) && ret[1] == 4 -> "V" + ret[2] + "." + ret[3] + "." + ret[4]
        guard data.count >= 5, data[0] == cmdFun, data[1] == 4 else { return nil }
        return "V\(data[2]).\(data[3]).\(data[4])"
    }

    public static func parseBatteryResponse(_ data: [UInt8]) -> Int? {
        guard data.count >= 3, data[0] == cmdFun, data[1] == 5 else { return nil }
        return Int(data[2])
    }

    public static func parseMACResponse(_ data: [UInt8]) -> String? {
        guard data.count >= 8, data[0] == cmdFun, data[1] == 6 else { return nil }
        let bytes = data[2..<8]
        return bytes.map { String(format: "%02X", $0) }.joined(separator: ":")
    }
}
