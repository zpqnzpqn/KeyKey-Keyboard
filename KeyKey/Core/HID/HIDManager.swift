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

        // 設定匹配字典
        let keyKeyMatch: [String: Any] = [
            kIOHIDVendorIDKey as String: Self.targetVendorID,
            kIOHIDProductIDKey as String: Self.keyboardProductID
        ]
        let powerOnMatch: [String: Any] = [
            kIOHIDVendorIDKey as String: Self.targetVendorID,
            kIOHIDProductIDKey as String: Self.powerOnProductID
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if device.kind == .keyboard {
                self.keyboardDevice = device
                self.isKeyboardConnected = true
                print("✅ KeyKey 鍵盤已連線")
            } else if device.kind == .poweron {
                self.powerOnDevice = device
                self.isPowerOnConnected = true
                print("✅ 無線開機模組已連線")
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

    // MARK: - 傳送工具方法
    public func sendKeyboardCommand(_ packet: [UInt8]) -> Bool {
        guard let device = keyboardDevice else { return false }
        return device.sendReport(packet)
    }

    public func sendPowerOnCommand(_ packet: [UInt8]) -> Bool {
        guard let device = powerOnDevice else { return false }
        return device.sendReport(packet)
    }

    public func readKeyboardReport() -> [UInt8]? {
        guard let device = keyboardDevice else { return nil }
        return device.getReport(reportID: 0, expectedLength: 64)
    }

    public func readPowerOnReport() -> [UInt8]? {
        guard let device = powerOnDevice else { return nil }
        return device.getReport(reportID: 0, expectedLength: 64)
    }
}
