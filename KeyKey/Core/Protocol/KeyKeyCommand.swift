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

    // MARK: - 單鍵封包 (65 位元組，含 VULN-05 邊界防呆)
    public static func makeKeyPacket(config: KeyConfig) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 65)
        packet[0] = 0 // Report ID (由 HIDDevice.sendReport 剝離後送出 64 bytes)
        packet[cmdTypeIndex] = cmdKey
        packet[keyLayerIndex] = 0 // KeyKey 固定為 Layer 0
        packet[keyIndex] = UInt8(min(max(config.keyIndex, 0), 1))
        packet[keyModeIndex] = config.mode.rawValue
        packet[keyTypeIndex] = config.type.rawValue

        switch config.type {
        case .keyboard:
            packet[keyModIndex] = config.modifiers.rawValue
            packet[keyCodeIndex] = config.keyCode
            packet[keyCodeIndex + 1] = 0
            packet[keyCodeIndex + 2] = 0
        case .consumer:
            // 原版協定: keyCode[0] (packet[6]) 為 lowByte, keyCode[1] (packet[7]) 為 highByte
            packet[keyModIndex] = config.keyCode
            packet[keyCodeIndex] = config.codeHigh
            packet[keyCodeIndex + 1] = 0
            packet[keyCodeIndex + 2] = 0
        case .mouse:
            // 原版協定: keyCode[0] (packet[6]) = 滑鼠按鍵遮罩, [7] = X 位移, [8] = Y 位移, [9] = 滾輪
            packet[keyModIndex] = config.mouseButtons.rawValue
            packet[keyCodeIndex] = UInt8(bitPattern: config.mouseMoveX)
            packet[keyCodeIndex + 1] = UInt8(bitPattern: config.mouseMoveY)
            packet[keyCodeIndex + 2] = UInt8(bitPattern: config.mouseWheel)
        }
        return packet
    }

    // MARK: - 巨集封包 (65 位元組，含 VULN-05 邊界防呆)
    public static func makeMacroPacket(macro: MacroConfig) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 65)
        packet[0] = 0 // Report ID
        packet[cmdTypeIndex] = cmdKey
        packet[keyLayerIndex] = 0 // KeyKey 固定為 Layer 0
        packet[keyIndex] = UInt8(min(max(macro.keyIndex, 0), 1))
        packet[keyModeIndex] = 2 // 巨集模式
        packet[macroTypeIndex] = macro.type == .mouse ? 3 : 1
        packet[macroLoopIndex] = macro.loopMode.rawValue

        if macro.type == .mouse {
            // 滑鼠巨集：最多 8 個步驟，每步驟佔 6 位元組：[Buttons, MoveX, MoveY, Wheel, PressDuration, DelayAfter]
            let maxSteps = min(macro.steps.count, 8)
            for i in 0..<maxSteps {
                let step = macro.steps[i]
                let offset = macroStartIndex + (i * 6)
                packet[offset] = step.mouseButtons.rawValue
                packet[offset + 1] = UInt8(bitPattern: step.mouseMoveX)
                packet[offset + 2] = UInt8(bitPattern: step.mouseMoveY)
                packet[offset + 3] = UInt8(bitPattern: step.mouseWheel)
                packet[offset + 4] = UInt8(min(max(step.pressDuration, 1), 250))
                packet[offset + 5] = UInt8(min(max(step.delayAfter, 1), 250))
            }
        } else {
            // 鍵盤巨集：最多 14 個步驟，每步驟佔 4 位元組：[Mod, KeyCode, PressDuration, DelayAfter]
            let maxSteps = min(macro.steps.count, 14)
            for i in 0..<maxSteps {
                let step = macro.steps[i]
                let offset = macroStartIndex + (i * 4)
                packet[offset] = step.modifiers.rawValue
                packet[offset + 1] = step.keyCode
                packet[offset + 2] = UInt8(min(max(step.pressDuration, 1), 250))
                packet[offset + 3] = UInt8(min(max(step.delayAfter, 1), 250))
            }
        }
        return packet
    }

    // MARK: - RGB 燈效封包 (17 位元組，含 VULN-05 邊界防呆)
    public static func makeRGBPacket(config: RGBConfig, keyIndex: UInt8) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 17)
        packet[0] = 0 // Report ID
        packet[cmdTypeIndex] = cmdRGB
        packet[rgbIndex] = min(keyIndex, 1) // 0: Key 1 LED, 1: Key 2 LED

        let clampedHue = min(max(Int(config.hue.rounded()), 0), 359)
        let hueInt = UInt16(clamping: clampedHue)
        packet[rgbHIndex] = UInt8((hueInt >> 8) & 0xFF)
        packet[rgbHIndex + 1] = UInt8(hueInt & 0xFF)

        // 原版韌體使用 QColor.hslSaturation() / lightness() 範圍 0 ~ 255
        let scaledS = Int((min(max(config.saturation, 0), 100) / 100.0 * 255.0).rounded())
        let scaledL = Int((min(max(config.lightness, 0), 100) / 100.0 * 255.0).rounded())
        packet[rgbSIndex] = UInt8(clamping: scaledS)
        packet[rgbLIndex] = UInt8(clamping: scaledL)

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

    // MARK: - 無線開機模組配對與解除配對命令 (原版雙向配對協定)
    /// 發送給鍵盤本體的配對綁定指令 (指定哪一顆按鍵作為無線開機鍵)
    public static func makePowerOnPairKeyboardPacket(layer: UInt8 = 0, keyIndex: UInt8) -> [UInt8] {
        [0, cmdFun, 7, 1, layer, keyIndex, 0, 0, 0, 0]
    }

    /// 發送給無線開機模組的 MAC 寫入配對指令
    public static func makePowerOnPairModulePacket(macBytes: [UInt8]) -> [UInt8] {
        var packet: [UInt8] = [0, cmdFun, 7, 2, 0, 0, 0, 0, 0, 0]
        for i in 0..<min(6, macBytes.count) {
            packet[4 + i] = macBytes[i]
        }
        return packet
    }

    /// 發送給鍵盤本體的解除配對指令
    public static let powerOnUnpairKeyboard: [UInt8] = [0, cmdFun, 7, 1, 255, 255, 0, 0, 0, 0]

    /// 發送給無線開機模組的解除配對指令
    public static let powerOnUnpairModule: [UInt8] = [0, cmdFun, 7, 2, 0, 0, 0, 0, 0, 0]

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

    public static func parseMACBytesResponse(_ data: [UInt8]) -> [UInt8]? {
        guard data.count >= 8, data[0] == cmdFun, data[1] == 6 else { return nil }
        return Array(data[2..<8])
    }
}
