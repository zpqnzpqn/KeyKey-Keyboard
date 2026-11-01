import SwiftUI
import Combine

@MainActor
public final class AppViewModel: ObservableObject {
    @Published public var currentLanguage: AppLanguage = .traditionalChinese
    @Published public var selectedKeyIndex: Int = 0 // 0: Key 1, 1: Key 2
    @Published public var selectedTab: NavigationTab = .keypad

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

    // MARK: - 設備查詢
    public func queryDeviceInfo() {
        _ = HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.getVersion)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if let report = HIDManager.shared.readKeyboardReport(),
               let ver = KeyKeyCommand.parseVersionResponse(report) {
                self?.deviceStatus.keyboardFirmwareVersion = ver
            }
        }
    }

    // MARK: - 按鍵儲存
    public func saveKeyConfig(for keyIndex: Int) {
        let config = keyIndex == 0 ? key1Config : key2Config
        let packet = KeyKeyCommand.makeKeyPacket(config: config)
        let success = HIDManager.shared.sendKeyboardCommand(packet)
        if success {
            notifyToast("鍵位 \(keyIndex + 1) 設定已成功儲存至設備")
        } else {
            notifyToast("儲存失敗：設備未連線或傳輸逾時")
        }
    }

    // MARK: - 巨集儲存
    public func saveMacroConfig(for keyIndex: Int) {
        let macro = keyIndex == 0 ? key1Macro : key2Macro
        let packet = KeyKeyCommand.makeMacroPacket(macro: macro)
        let success = HIDManager.shared.sendKeyboardCommand(packet)
        if success {
            notifyToast("鍵位 \(keyIndex + 1) 巨集序列已成功儲存至設備")
        } else {
            notifyToast("儲存失敗：設備未連線或傳輸逾時")
        }
    }

    // MARK: - RGB 燈效儲存
    public func saveRGBConfig() {
        let packet = KeyKeyCommand.makeRGBPacket(config: rgbConfig)
        let success = HIDManager.shared.sendKeyboardCommand(packet)
        if success {
            notifyToast("RGB 燈效設定已成功寫入設備")
        } else {
            notifyToast("寫入失敗：設備未連線")
        }
    }

    // MARK: - 無線開機模組操作
    public func pairPowerOnModule() {
        let success = HIDManager.shared.sendPowerOnCommand(KeyKeyCommand.powerOnPair)
        if success {
            notifyToast("已發送配對指令，請將開機模組靠近主機")
        } else {
            notifyToast("開機模組未連線")
        }
    }

    public func unpairPowerOnModule() {
        let success = HIDManager.shared.sendPowerOnCommand(KeyKeyCommand.powerOnUnpair)
        if success {
            notifyToast("已成功解除開機模組配對")
        } else {
            notifyToast("開機模組未連線")
        }
    }

    // MARK: - 即時按鍵錄製
    public func startMacroRecording() {
        isRecordingMacro = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self, self.isRecordingMacro else { return event }
            let keyCode = UInt8(clamping: event.keyCode)
            var mask = ModifierMask()
            if event.modifierFlags.contains(.control) { mask.insert(.leftCtrl) }
            if event.modifierFlags.contains(.shift) { mask.insert(.leftShift) }
            if event.modifierFlags.contains(.option) { mask.insert(.leftAlt) }
            if event.modifierFlags.contains(.command) { mask.insert(.leftGUI) }

            let step = MacroStep(modifiers: mask, keyCode: keyCode, pressDuration: 5, delayAfter: 5)
            if self.selectedKeyIndex == 0 {
                if self.key1Macro.steps.count < 14 {
                    self.key1Macro.steps.append(step)
                }
            } else {
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
