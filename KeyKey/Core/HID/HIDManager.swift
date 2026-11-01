import Foundation
import Combine
import IOKit
import IOKit.hid

/// 管理 macOS IOHIDManager 生命週期與熱插拔監聽
public final class HIDManager: ObservableObject {
    public static let shared = HIDManager()

    @Published public private(set) var keyboardDevice: HIDDevice?
    @Published public private(set) var powerOnDevice: HIDDevice?
    @Published public private(set) var isKeyboardConnected: Bool = false
    @Published public private(set) var isPowerOnConnected: Bool = false

    public let keyboardReportSubject = PassthroughSubject<[UInt8], Never>()
    public let powerOnReportSubject = PassthroughSubject<[UInt8], Never>()
    private var lastKeyboardReport: [UInt8]?
    private var lastPowerOnReport: [UInt8]?

    /// 每次寫入 CH57x DataFlash 之最小安全間隔 (60ms)，防止連續發送封包遭 MCU 靜默丟棄 (VULN-04)
    public static let minimumWriteInterval: TimeInterval = 0.060
    private var lastKeyboardWriteUptime: TimeInterval = 0
    private var lastPowerOnWriteUptime: TimeInterval = 0
    private var heartbeatWorkItem: DispatchWorkItem?

    private var managerRef: IOHIDManager?

    // VID & PID
    public static let targetVendorID = 21090 // 0x5262
    public static let keyboardProductID = 19275 // 0x4B4B ('KK')
    public static let powerOnProductID = 20559 // 0x504F ('PO')

    public init() {
        setupManager()
    }

    deinit {
        stop()
    }

    private func setupManager() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.managerRef = manager

        // 設定匹配字典（僅匹配 Interface 3: PrimaryUsagePage=1, PrimaryUsage=0 的 64-byte Vendor 控制介面）
        let keyKeyMatch: [String: Any] = [
            kIOHIDVendorIDKey as String: Self.targetVendorID,
            kIOHIDProductIDKey as String: Self.keyboardProductID,
            kIOHIDPrimaryUsagePageKey as String: 1,
            kIOHIDPrimaryUsageKey as String: 0
        ]
        let powerOnMatch: [String: Any] = [
            kIOHIDVendorIDKey as String: Self.targetVendorID,
            kIOHIDProductIDKey as String: Self.powerOnProductID,
            kIOHIDPrimaryUsagePageKey as String: 1,
            kIOHIDPrimaryUsageKey as String: 0
        ]

        let matchingList = [keyKeyMatch, powerOnMatch] as CFArray
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchingList)

        let context = Unmanaged.passUnretained(self).toOpaque()

        // 設備插入回呼
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, result, sender, deviceRef in
            guard let context = context else { return }
            let this = Unmanaged<HIDManager>.fromOpaque(context).takeUnretainedValue()
            this.handleDeviceAttached(deviceRef: deviceRef)
        }, context)

        // 設備拔出回呼
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, result, sender, deviceRef in
            guard let context = context else { return }
            let this = Unmanaged<HIDManager>.fromOpaque(context).takeUnretainedValue()
            this.handleDeviceRemoved(deviceRef: deviceRef)
        }, context)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if openResult != kIOReturnSuccess {
            print("⚠️ IOHIDManagerOpen 失敗，傳回碼: \(openResult)")
        }
    }

    public func stop() {
        if let manager = managerRef {
            IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            self.managerRef = nil
        }
    }

    private func handleDeviceAttached(deviceRef: IOHIDDevice) {
        let device = HIDDevice(deviceRef: deviceRef)
        guard device.isVendorControlInterface else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if device.kind == .keyboard {
                device.onInputReport = { [weak self] report in
                    DispatchQueue.main.async {
                        self?.lastKeyboardReport = report
                        self?.keyboardReportSubject.send(report)
                    }
                }
                self.keyboardDevice = device
                self.isKeyboardConnected = true
                print("✅ KeyKey 鍵盤已連線 (UsagePage=\(device.primaryUsagePage), Usage=\(device.primaryUsage), MaxOut=\(device.maxOutputReportSize))")
            } else if device.kind == .poweron {
                device.onInputReport = { [weak self] report in
                    DispatchQueue.main.async {
                        self?.lastPowerOnReport = report
                        self?.powerOnReportSubject.send(report)
                    }
                }
                self.powerOnDevice = device
                self.isPowerOnConnected = true
                print("✅ 無線開機模組已連線 (UsagePage=\(device.primaryUsagePage), Usage=\(device.primaryUsage), MaxOut=\(device.maxOutputReportSize))")
            }
        }
    }

    private func handleDeviceRemoved(deviceRef: IOHIDDevice) {
        let device = HIDDevice(deviceRef: deviceRef)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if device.kind == .keyboard {
                if self.keyboardDevice?.id == device.id {
                    self.keyboardDevice = nil
                    self.isKeyboardConnected = false
                    print("❌ KeyKey 鍵盤已斷開")
                }
            } else if device.kind == .poweron {
                if self.powerOnDevice?.id == device.id {
                    self.powerOnDevice = nil
                    self.isPowerOnConnected = false
                    print("❌ 無線開機模組已斷開")
                }
            }
        }
    }

    // MARK: - 傳送工具方法 (含 60ms 寫入節流與 Heartbeat 存活確認)
    public func sendKeyboardCommand(_ packet: [UInt8]) -> Bool {
        guard let device = keyboardDevice else { return false }
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = now - lastKeyboardWriteUptime
        if elapsed < Self.minimumWriteInterval && lastKeyboardWriteUptime > 0 {
            Thread.sleep(forTimeInterval: Self.minimumWriteInterval - elapsed)
        }
        let ok = device.sendReport(packet)
        lastKeyboardWriteUptime = ProcessInfo.processInfo.systemUptime

        // 若為 DataFlash 配置寫入指令 (cmdType == 1 按鍵/巨集 或 cmdType == 2 RGB)，排程 Heartbeat 確認 MCU 存活
        let cmdType = packet.count > 1 ? packet[1] : 0
        if ok && (cmdType == 1 || cmdType == 2) {
            scheduleLivenessHeartbeat()
        }
        return ok
    }

    public func sendPowerOnCommand(_ packet: [UInt8]) -> Bool {
        guard let device = powerOnDevice else { return false }
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = now - lastPowerOnWriteUptime
        if elapsed < Self.minimumWriteInterval && lastPowerOnWriteUptime > 0 {
            Thread.sleep(forTimeInterval: Self.minimumWriteInterval - elapsed)
        }
        let ok = device.sendReport(packet)
        lastPowerOnWriteUptime = ProcessInfo.processInfo.systemUptime
        return ok
    }

    private func scheduleLivenessHeartbeat() {
        heartbeatWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self = self, self.isKeyboardConnected else { return }
            _ = self.keyboardDevice?.sendReport(KeyKeyCommand.getVersion)
        }
        heartbeatWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10, execute: item)
    }

    public func readKeyboardReport() -> [UInt8]? {
        if let report = lastKeyboardReport {
            return report
        }
        guard let device = keyboardDevice else { return nil }
        return device.getReport(reportID: 0, expectedLength: 64)
    }

    public func readPowerOnReport() -> [UInt8]? {
        if let report = lastPowerOnReport {
            return report
        }
        guard let device = powerOnDevice else { return nil }
        return device.getReport(reportID: 0, expectedLength: 64)
    }
}
