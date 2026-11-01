import SwiftUI
import Combine

@MainActor
public final class AppViewModel: ObservableObject {
    @Published public var currentLanguage: AppLanguage = .traditionalChinese
    @Published public var selectedKeyIndex: Int = 0 // 0: Key 1, 1: Key 2
    @Published public var selectedTab: NavigationTab = .keypad

    // 鍵位方向與開機模組配對鍵設定
    /// true = 比照原版硬體視覺方向 (左鍵為按鍵 2 / index 1，右鍵為按鍵 1 / index 0)
    @Published public var swapKeyOrder: Bool = true
    /// 無線開機模組綁定之按鍵索引 (0: 按鍵 1, 1: 按鍵 2)
    @Published public var powerOnPairKeyIndex: Int = 0

    // 鍵位與巨集狀態
    @Published public var key1Config: KeyConfig = KeyConfig(keyIndex: 0, keyCode: 29) // 'Z'
    @Published public var key2Config: KeyConfig = KeyConfig(keyIndex: 1, keyCode: 27) // 'X'
    @Published public var key1Macro: MacroConfig = MacroConfig(keyIndex: 0, steps: [
        MacroStep(keyCode: 29, pressDuration: 5, delayAfter: 5)
    ])
    @Published public var key2Macro: MacroConfig = MacroConfig(keyIndex: 1, steps: [
        MacroStep(keyCode: 27, pressDuration: 5, delayAfter: 5)
    ])

    // RGB 狀態
    @Published public var rgbConfig: RGBConfig = RGBConfig()

    // 設備狀態
    @Published public var deviceStatus: DeviceStatus = DeviceStatus()
    @Published public var toastMessage: String? = nil
    @Published public var showToast: Bool = false

    // 鍵位即時測試區狀態
    @Published public var keyTestLogs: [String] = []
    @Published public var keyTestCount: Int = 0

    // 巨集即時錄製中
    @Published public var isRecordingMacro: Bool = false
    private var eventMonitor: Any?

    private var cancellables = Set<AnyCancellable>()

    public enum NavigationTab: String, CaseIterable, Identifiable {
        case keypad = "按鍵自訂"
        case macro = "巨集編程"
        case rgb = "RGB 燈效"
        case powerOn = "開機模組"
        case tester = "按鍵測試"
        case firmware = "韌體升級"
        case settings = "偏好設定"

        public var id: String { rawValue }

        public var iconName: String {
            switch self {
            case .keypad: return "keyboard"
            case .macro: return "command"
            case .rgb: return "paintpalette"
            case .powerOn: return "power"
            case .tester: return "waveform.path.ecg"
            case .firmware: return "arrow.triangle.2.circlepath"
            case .settings: return "gearshape"
            }
        }
    }

    public init() {
        setupBindings()
    }

    private func setupBindings() {
        // 監聽鍵盤 Interrupt IN 報告 (版本、電量、藍牙 MAC)
        HIDManager.shared.keyboardReportSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] report in
                guard let self = self else { return }
                if let ver = KeyKeyCommand.parseVersionResponse(report) {
                    self.deviceStatus.keyboardFirmwareVersion = ver
                } else if let bat = KeyKeyCommand.parseBatteryResponse(report) {
                    self.deviceStatus.batteryLevel = bat
                } else if let mac = KeyKeyCommand.parseMACResponse(report),
                          let macBytes = KeyKeyCommand.parseMACBytesResponse(report) {
                    self.deviceStatus.bluetoothMac = mac
                    self.deviceStatus.macBytes = macBytes
                }
            }
            .store(in: &cancellables)

        // 監聽無線開機模組 Interrupt IN 報告
        HIDManager.shared.powerOnReportSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] report in
                guard let self = self else { return }
                if let ver = KeyKeyCommand.parseVersionResponse(report) {
                    self.deviceStatus.poweronFirmwareVersion = ver
                }
            }
            .store(in: &cancellables)

        // 監聽 HID 連線狀態
        HIDManager.shared.$isKeyboardConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                guard let self = self else { return }
                self.deviceStatus.isKeyboardConnected = connected
                if connected {
                    self.notifyToast("KeyKey 鍵盤已連線")
                    self.queryDeviceInfo()
                } else {
                    self.deviceStatus.keyboardFirmwareVersion = "未偵測"
                    self.deviceStatus.batteryLevel = nil
                    self.notifyToast("KeyKey 鍵盤已中斷連線")
                }
            }
            .store(in: &cancellables)

        HIDManager.shared.$isPowerOnConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                guard let self = self else { return }
                self.deviceStatus.isPowerOnConnected = connected
                if connected {
                    self.notifyToast("無線開機模組已連線")
                    self.queryPowerOnInfo()
                } else {
                    self.deviceStatus.poweronFirmwareVersion = "未偵測"
                }
            }
            .store(in: &cancellables)
    }

    public func notifyToast(_ message: String) {
        toastMessage = message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            if self?.toastMessage == message {
                self?.showToast = false
            }
        }
    }

    // MARK: - 設備查詢 (版本 / 電量 / MAC)
    public func queryDeviceInfo() {
        if HIDManager.shared.isKeyboardConnected {
            _ = HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.getVersion)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                _ = HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.getBattery)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                _ = HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.getMAC)
            }
        }
        if HIDManager.shared.isPowerOnConnected {
            queryPowerOnInfo()
        }
    }

    public func queryPowerOnInfo() {
        _ = HIDManager.shared.sendPowerOnCommand(KeyKeyCommand.getVersion)
    }

    // MARK: - 按鍵儲存
    public func saveKeyConfig(for keyIndex: Int) {
        if keyIndex == 0 {
            key1Config.keyIndex = 0
            key1Config.mode = .single
        } else {
            key2Config.keyIndex = 1
            key2Config.mode = .single
        }
        let config = keyIndex == 0 ? key1Config : key2Config
        let packet = KeyKeyCommand.makeKeyPacket(config: config)
        let success = HIDManager.shared.sendKeyboardCommand(packet)
        if success {
            notifyToast("按鍵 \(keyIndex + 1) 設定已成功儲存至設備")
        } else {
            notifyToast("儲存失敗：設備未連線或傳輸逾時")
        }
    }

    // MARK: - 巨集儲存
    public func saveMacroConfig(for keyIndex: Int) {
        if keyIndex == 0 {
            key1Macro.keyIndex = 0
            key1Config.mode = .macro
        } else {
            key2Macro.keyIndex = 1
            key2Config.mode = .macro
        }
        let macro = keyIndex == 0 ? key1Macro : key2Macro
        let packet = KeyKeyCommand.makeMacroPacket(macro: macro)
        let success = HIDManager.shared.sendKeyboardCommand(packet)
        if success {
            notifyToast("按鍵 \(keyIndex + 1) 巨集序列已成功儲存至設備")
        } else {
            notifyToast("儲存失敗：設備未連線或傳輸逾時")
        }
    }

    // MARK: - RGB 燈效儲存
    public func saveRGBConfig() {
        let indices = rgbConfig.target.hardwareIndices
        var allSuccess = true
        for idx in indices {
            let packet = KeyKeyCommand.makeRGBPacket(config: rgbConfig, keyIndex: idx)
            if !HIDManager.shared.sendKeyboardCommand(packet) {
                allSuccess = false
            }
        }
        if allSuccess {
            notifyToast("RGB 燈效設定 (\(rgbConfig.target.displayName)) 已成功寫入設備")
        } else {
            notifyToast("寫入失敗：設備未連線")
        }
    }

    // MARK: - 一鍵安全初始化與整份設定檔硬體同步 (防範 VULN-02 / VULN-04)
    /// 強制覆寫硬體內部 Write-Only Flash，消除未知或惡意殘留巨集並恢復預設 Z / X 單鍵與彩虹燈效
    public func factorySafeReset() {
        key1Config = KeyConfig(layer: 0, keyIndex: 0, mode: .single, type: .keyboard, modifiers: [], keyCode: 29) // 'Z'
        key2Config = KeyConfig(layer: 0, keyIndex: 1, mode: .single, type: .keyboard, modifiers: [], keyCode: 27) // 'X'
        key1Macro = MacroConfig(layer: 0, keyIndex: 0, type: .keyboard, loopMode: .count(1), steps: [
            MacroStep(keyCode: 29, pressDuration: 5, delayAfter: 5)
        ])
        key2Macro = MacroConfig(layer: 0, keyIndex: 1, type: .keyboard, loopMode: .count(1), steps: [
            MacroStep(keyCode: 27, pressDuration: 5, delayAfter: 5)
        ])
        rgbConfig = RGBConfig(target: .all, mainMode: .nightlight, triggerMode: .customColor, nightlightMode: .rainbow, hue: 180.0, saturation: 80.0, lightness: 50.0)

        guard deviceStatus.isKeyboardConnected else {
            notifyToast("已重設軟體端配置（鍵盤未連線，連線後請再次點擊以覆寫硬體）")
            return
        }

        let ok1 = HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.makeKeyPacket(config: key1Config))
        let ok2 = HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.makeKeyPacket(config: key2Config))
        let ok3 = HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.makeRGBPacket(config: rgbConfig, keyIndex: 0))
        let ok4 = HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.makeRGBPacket(config: rgbConfig, keyIndex: 1))

        if ok1 && ok2 && ok3 && ok4 {
            notifyToast("安全初始化完成：已強制覆寫雙鍵為預設單鍵 (Z/X) 並清除硬體巨集")
        } else {
            notifyToast("安全初始化部分失敗，請檢查 USB 連線")
        }
    }

    /// 將目前載入之完整設定檔（按鍵 1、按鍵 2 與 RGB 燈效）依序以 60ms 節流同步寫入硬體
    public func applyCurrentProfileToHardware(profileName: String? = nil) {
        guard deviceStatus.isKeyboardConnected else {
            if let name = profileName {
                notifyToast("已匯入設定檔「\(name)」（鍵盤未連線，僅更新畫面）")
            }
            return
        }

        let pkt1 = key1Config.mode == .macro
            ? KeyKeyCommand.makeMacroPacket(macro: key1Macro)
            : KeyKeyCommand.makeKeyPacket(config: key1Config)
        let pkt2 = key2Config.mode == .macro
            ? KeyKeyCommand.makeMacroPacket(macro: key2Macro)
            : KeyKeyCommand.makeKeyPacket(config: key2Config)

        var allOK = HIDManager.shared.sendKeyboardCommand(pkt1) && HIDManager.shared.sendKeyboardCommand(pkt2)
        for idx in rgbConfig.target.hardwareIndices {
            let rgbPkt = KeyKeyCommand.makeRGBPacket(config: rgbConfig, keyIndex: idx)
            if !HIDManager.shared.sendKeyboardCommand(rgbPkt) {
                allOK = false
            }
        }

        if allOK {
            if let name = profileName {
                notifyToast("已成功匯入「\(name)」並完整同步寫入硬體")
            } else {
                notifyToast("已將全部配置同步寫入硬體")
            }
        } else {
            notifyToast("同步寫入硬體時發生部分失敗")
        }
    }

    // MARK: - USB / 藍牙模式切換
    public func switchToUSBMode() {
        if HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.setUSBMode) {
            notifyToast("已切換為 USB 有線優先模式")
        } else {
            notifyToast("切換失敗：鍵盤未連線")
        }
    }

    public func switchToBLEMode() {
        if HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.setBLEMode) {
            notifyToast("已切換為 Bluetooth 藍牙無線模式")
        } else {
            notifyToast("切換失敗：鍵盤未連線")
        }
    }

    // MARK: - 無線開機模組操作 (原版雙向配對協定)
    public func pairPowerOnModule() {
        guard deviceStatus.isKeyboardConnected && deviceStatus.isPowerOnConnected else {
            notifyToast("配對失敗：請同時連接 KeyKey 小鍵盤與無線開機模組")
            return
        }
        guard deviceStatus.macBytes.count == 6 else {
            _ = HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.getMAC)
            notifyToast("正在讀取鍵盤藍牙 MAC 位址，請稍候再試一次")
            return
        }

        let kbPacket = KeyKeyCommand.makePowerOnPairKeyboardPacket(layer: 0, keyIndex: UInt8(powerOnPairKeyIndex))
        let modPacket = KeyKeyCommand.makePowerOnPairModulePacket(macBytes: deviceStatus.macBytes)

        let ok1 = HIDManager.shared.sendKeyboardCommand(kbPacket)
        let ok2 = HIDManager.shared.sendPowerOnCommand(modPacket)
        if ok1 && ok2 {
            notifyToast("已成功將「按鍵 \(powerOnPairKeyIndex + 1)」與無線開機模組完成配對")
        } else {
            notifyToast("配對指令發送失敗，請檢查 USB 連線")
        }
    }

    public func unpairPowerOnModule() {
        var anySuccess = false
        if deviceStatus.isKeyboardConnected {
            if HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.powerOnUnpairKeyboard) {
                anySuccess = true
            }
        }
        if deviceStatus.isPowerOnConnected {
            if HIDManager.shared.sendPowerOnCommand(KeyKeyCommand.powerOnUnpairModule) {
                anySuccess = true
            }
        }
        if anySuccess {
            notifyToast("已成功解除無線開機模組配對")
        } else {
            notifyToast("解除失敗：設備未連線")
        }
    }

    // MARK: - 即時按鍵錄製
    public func startMacroRecording() {
        isRecordingMacro = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self, self.isRecordingMacro else { return event }
            guard let hidCode = KeyDefinitions.hidUsage(fromMacKeyCode: event.keyCode) else {
                return nil
            }
            var mask = ModifierMask()
            if event.modifierFlags.contains(.control) { mask.insert(.leftCtrl) }
            if event.modifierFlags.contains(.shift) { mask.insert(.leftShift) }
            if event.modifierFlags.contains(.option) { mask.insert(.leftAlt) }
            if event.modifierFlags.contains(.command) { mask.insert(.leftGUI) }

            let step = MacroStep(modifiers: mask, keyCode: hidCode, pressDuration: 5, delayAfter: 5)
            if self.selectedKeyIndex == 0 {
                self.key1Macro.type = .keyboard
                if self.key1Macro.steps.count < 14 {
                    self.key1Macro.steps.append(step)
                }
            } else {
                self.key2Macro.type = .keyboard
                if self.key2Macro.steps.count < 14 {
                    self.key2Macro.steps.append(step)
                }
            }
            return nil // 吸收事件不傳播
        }
    }

    public func stopMacroRecording() {
        isRecordingMacro = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - 鍵位測試區
    public func recordTestKey(name: String) {
        keyTestCount += 1
        let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        keyTestLogs.insert("[\(timeStr)] 擊鍵 #\(keyTestCount): \(name)", at: 0)
        if keyTestLogs.count > 50 {
            keyTestLogs.removeLast()
        }
    }

    public func clearTestLogs() {
        keyTestLogs.removeAll()
        keyTestCount = 0
    }
}
