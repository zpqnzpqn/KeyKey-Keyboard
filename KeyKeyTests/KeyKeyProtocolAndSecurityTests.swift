import XCTest

final class KeyKeyProtocolAndSecurityTests: XCTestCase {

    // MARK: - 1. 64-Byte HID Command Framing & Boundary Clamping (VULN-05)

    func testSingleKeyCommandFramingAndClamping() {
        let config = KeyConfig(
            layer: 5,       // Out of bounds -> clamped to 0
            keyIndex: 99,   // Out of bounds -> clamped to 1
            mode: .single,
            type: .keyboard,
            modifiers: [.leftCtrl, .leftGUI],
            keyCode: 0x04
        )
        let packet = KeyKeyCommand.makeKeyPacket(config: config)

        XCTAssertEqual(packet.count, 65, "Internal packet with Report ID prefix must be 65 bytes (64 bytes after stripping Report ID)")
        XCTAssertEqual(packet[0], 0x00, "Report ID must be 0x00")
        XCTAssertEqual(packet[KeyKeyCommand.cmdTypeIndex], KeyKeyCommand.cmdKey)
        XCTAssertEqual(packet[KeyKeyCommand.keyLayerIndex], 0x00, "layer 5 must be clamped to 0")
        XCTAssertEqual(packet[KeyKeyCommand.keyIndex], 0x01, "keyIndex 99 must be clamped to 1")
        XCTAssertEqual(packet[KeyKeyCommand.keyModeIndex], KeyMode.single.rawValue)
        XCTAssertEqual(packet[KeyKeyCommand.keyTypeIndex], KeyType.keyboard.rawValue)
        XCTAssertEqual(packet[KeyKeyCommand.keyModIndex], ModifierMask([.leftCtrl, .leftGUI]).rawValue)
        XCTAssertEqual(packet[KeyKeyCommand.keyCodeIndex], 0x04)
    }

    func testMacroKeyCommandFramingAndStepClamping() {
        let steps = [
            MacroStep(modifiers: [.leftGUI], keyCode: 44, pressDuration: 0, delayAfter: 255), // Out-of-bounds timings
            MacroStep(modifiers: [], keyCode: 4, pressDuration: 10, delayAfter: 20)
        ]
        let macro = MacroConfig(
            layer: 3,
            keyIndex: -3, // Out of bounds -> clamped to 0
            type: .keyboard,
            loopMode: .infinite,
            steps: steps
        )
        let packet = KeyKeyCommand.makeMacroPacket(macro: macro)

        XCTAssertEqual(packet.count, 65)
        XCTAssertEqual(packet[KeyKeyCommand.cmdTypeIndex], KeyKeyCommand.cmdKey)
        XCTAssertEqual(packet[KeyKeyCommand.keyLayerIndex], 0x00)
        XCTAssertEqual(packet[KeyKeyCommand.keyIndex], 0x00, "Negative keyIndex must be clamped to 0")
        XCTAssertEqual(packet[KeyKeyCommand.keyModeIndex], 2, "Macro mode must be 2")
        XCTAssertEqual(packet[KeyKeyCommand.macroTypeIndex], 1, "Keyboard macro type must be 1")
        XCTAssertEqual(packet[KeyKeyCommand.macroLoopIndex], 255, "Infinite loop mode must encode as 255 (0xFF)")

        // Step 0 starts at byte 7
        XCTAssertEqual(packet[7], ModifierMask.leftGUI.rawValue)
        XCTAssertEqual(packet[8], 44)
        XCTAssertEqual(packet[9], 1, "pressDuration 0 must be clamped to 1 (10ms)")
        XCTAssertEqual(packet[10], 250, "delayAfter 255 must be clamped to 250 (2500ms)")

        // Step 1 starts at byte 11
        XCTAssertEqual(packet[11], 0x00)
        XCTAssertEqual(packet[12], 4)
        XCTAssertEqual(packet[13], 10)
        XCTAssertEqual(packet[14], 20)
    }

    func testRGBCommandEncodingAndClamping() {
        let config = RGBConfig(
            target: .all,
            mainMode: .nightlight,
            triggerMode: .customColor,
            nightlightMode: .rainbow,
            hue: 400.0,        // Should clamp to 359 (0x0167)
            saturation: 150.0, // Should clamp to 100 -> scaled to 255
            lightness: -10.0   // Should clamp to 0 -> scaled to 0
        )
        let indices = config.target.hardwareIndices
        XCTAssertEqual(indices, [0, 1], "RGBTarget.all must target LED 0 and LED 1")

        let packet0 = KeyKeyCommand.makeRGBPacket(config: config, keyIndex: indices[0])
        let packet1 = KeyKeyCommand.makeRGBPacket(config: config, keyIndex: 9) // Out of bounds -> clamped to 1

        XCTAssertEqual(packet0[KeyKeyCommand.cmdTypeIndex], KeyKeyCommand.cmdRGB)
        XCTAssertEqual(packet0[KeyKeyCommand.rgbIndex], 0)
        XCTAssertEqual(packet1[KeyKeyCommand.rgbIndex], 1)
        XCTAssertEqual(packet0[KeyKeyCommand.rgbHIndex], 0x01, "Hue 359 high byte must be 0x01")
        XCTAssertEqual(packet0[KeyKeyCommand.rgbHIndex + 1], 0x67, "Hue 359 low byte must be 0x67")
        XCTAssertEqual(packet0[KeyKeyCommand.rgbSIndex], 255, "Saturation 100% must scale to 255")
        XCTAssertEqual(packet0[KeyKeyCommand.rgbLIndex], 0, "Lightness 0% must scale to 0")
        XCTAssertEqual(packet0[KeyKeyCommand.rgbMode1Index], 2, "Nightlight mode must encode as 2")
        XCTAssertEqual(packet0[KeyKeyCommand.rgbMode2Index], RGBNightlightMode.rainbow.rawValue)
    }

    // MARK: - 2. Device Telemetry Response Parsing

    func testDeviceTelemetryResponseParsing() {
        let verReport: [UInt8] = [3, 4, 1, 0, 2, 0, 0, 0]
        XCTAssertEqual(KeyKeyCommand.parseVersionResponse(verReport), "V1.0.2")

        let batReport: [UInt8] = [3, 5, 95, 0, 0, 0]
        XCTAssertEqual(KeyKeyCommand.parseBatteryResponse(batReport), 95)

        let macReport: [UInt8] = [3, 6, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
        XCTAssertEqual(KeyKeyCommand.parseMACResponse(macReport), "AA:BB:CC:DD:EE:FF")
        XCTAssertEqual(KeyKeyCommand.parseMACBytesResponse(macReport), [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF])
    }

    // MARK: - 3. Macro Safety Auditor & Profile Sanitization (VULN-02 & VULN-05)

    func testMacroSafetyAuditorDetectsHighRiskAndInfiniteFlood() {
        // Cmd + Space (keyCode 44) -> Spotlight launcher warning
        let spotlightMacro = MacroConfig(
            keyIndex: 0,
            type: .keyboard,
            loopMode: .count(1),
            steps: [MacroStep(modifiers: [.leftGUI], keyCode: 44, pressDuration: 10, delayAfter: 10)]
        )
        XCTAssertFalse(
            MacroSafetyAuditor.inspect(macro: spotlightMacro).isEmpty,
            "Cmd+Space macro must trigger a high-risk launcher warning"
        )

        // Infinite loop with <= 20ms total cycle -> Flood warning
        let floodMacro = MacroConfig(
            keyIndex: 1,
            type: .keyboard,
            loopMode: .infinite,
            steps: [MacroStep(modifiers: [], keyCode: 4, pressDuration: 1, delayAfter: 1)]
        )
        XCTAssertFalse(
            MacroSafetyAuditor.inspect(macro: floodMacro).isEmpty,
            "Ultra-fast infinite macro must trigger an input flood warning"
        )

        // Benign Cmd+C macro -> No warnings
        let safeMacro = MacroConfig(
            keyIndex: 0,
            type: .keyboard,
            loopMode: .count(1),
            steps: [MacroStep(modifiers: [.leftGUI], keyCode: 6, pressDuration: 10, delayAfter: 10)]
        )
        XCTAssertTrue(
            MacroSafetyAuditor.inspect(macro: safeMacro).isEmpty,
            "Standard copy macro must not trigger warnings"
        )
    }

    func testProfileSanitizationClampsOutOfBoundsDeserializedValues() {
        let overlongSteps = (0..<20).map { _ in
            MacroStep(modifiers: [], keyCode: 4, pressDuration: 0, delayAfter: 999)
        }
        let rawProfile = KeyKeyProfile(
            profileName: "Untrusted",
            key1Config: KeyConfig(layer: 9, keyIndex: 42),
            key2Config: KeyConfig(layer: 7, keyIndex: -5),
            key1Macro: MacroConfig(layer: 4, keyIndex: 99, type: .keyboard, loopMode: .count(999), steps: overlongSteps),
            key2Macro: MacroConfig(layer: 2, keyIndex: -1, type: .mouse, loopMode: .count(0), steps: overlongSteps),
            rgbConfig: RGBConfig(target: .all, hue: 999.0, saturation: -5.0, lightness: 200.0)
        )

        let sanitized = rawProfile.sanitized()
        XCTAssertEqual(sanitized.key1Config.layer, 0)
        XCTAssertEqual(sanitized.key1Config.keyIndex, 0)
        XCTAssertEqual(sanitized.key2Config.layer, 0)
        XCTAssertEqual(sanitized.key2Config.keyIndex, 1)

        XCTAssertEqual(sanitized.key1Macro.layer, 0)
        XCTAssertEqual(sanitized.key1Macro.keyIndex, 0)
        XCTAssertEqual(sanitized.key1Macro.loopMode, .count(250))
        XCTAssertEqual(sanitized.key1Macro.steps.count, 14, "Keyboard macro steps must be truncated to hardware limit of 14")
        XCTAssertEqual(sanitized.key1Macro.steps[0].pressDuration, 1)
        XCTAssertEqual(sanitized.key1Macro.steps[0].delayAfter, 250)

        XCTAssertEqual(sanitized.key2Macro.keyIndex, 1)
        XCTAssertEqual(sanitized.key2Macro.loopMode, .count(1))
        XCTAssertEqual(sanitized.key2Macro.steps.count, 8, "Mouse macro steps must be truncated to hardware limit of 8")

        XCTAssertEqual(sanitized.rgbConfig.hue, 359.0)
        XCTAssertEqual(sanitized.rgbConfig.saturation, 0.0)
        XCTAssertEqual(sanitized.rgbConfig.lightness, 100.0)
    }

    // MARK: - 4. Firmware DFU Validator (VULN-01)

    func testFirmwareValidatorSizeAndHeaderChecks() {
        // 1. Empty firmware -> invalid
        let emptyResult = FirmwareValidator.validate(data: Data())
        XCTAssertFalse(emptyResult.isValid, "Empty firmware data must be rejected")

        // 2. Oversized firmware (> 448KB CH573F Flash limit) -> invalid
        let oversized = Data(repeating: 0x12, count: FirmwareValidator.maxFirmwareBytes + 4)
        let oversizedResult = FirmwareValidator.validate(data: oversized)
        XCTAssertFalse(oversizedResult.isValid, "Firmware exceeding 448KB CH573F Flash limit must be rejected")

        // 3. Blank 0xFF header -> invalid
        let blankImage = Data(repeating: 0xFF, count: 8192)
        let blankResult = FirmwareValidator.validate(data: blankImage)
        XCTAssertFalse(blankResult.isValid, "All-0xFF blank image without vector table must be rejected")

        // 4. Valid size (8KB) with non-blank CH57x vector header -> valid (unverified custom)
        var validCustom = Data(repeating: 0xFF, count: 8192)
        validCustom[0] = 0x6F
        validCustom[1] = 0x00
        validCustom[2] = 0x80
        validCustom[3] = 0x00
        let customResult = FirmwareValidator.validate(data: validCustom, fileName: "KeyKey_V103.bin", target: .keyboard)
        XCTAssertTrue(customResult.isValid, "Valid CH57x firmware header should pass validation")
        XCTAssertTrue(customResult.isRISCVHeaderValid)
        XCTAssertFalse(customResult.isOfficialVerified, "Custom image should require user confirmation as unverified")
        XCTAssertEqual(customResult.sha256Hex.count, 64)
    }
}
