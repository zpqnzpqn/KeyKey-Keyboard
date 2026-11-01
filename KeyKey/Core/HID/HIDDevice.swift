import Foundation
import IOKit
import IOKit.hid

public enum DeviceKind: String, Codable {
    case keyboard = "KeyKey 鍵盤"
    case poweron = "無線開機模組"
    case unknown = "未知設備"
}

/// 封裝單一 IOHIDDevice 實例
public final class HIDDevice: Identifiable {
    public let id: String
    public let deviceRef: IOHIDDevice
    public let vendorID: Int
    public let productID: Int
    public let primaryUsagePage: Int
    public let primaryUsage: Int
    public let maxInputReportSize: Int
    public let maxOutputReportSize: Int
    public let kind: DeviceKind
    public let transport: String

    public var onInputReport: (([UInt8]) -> Void)?
    private let inputBuffer: UnsafeMutablePointer<UInt8>
    private let inputBufferSize: Int = 64

    public init(deviceRef: IOHIDDevice) {
        self.deviceRef = deviceRef

        let vid = IOHIDDeviceGetProperty(deviceRef, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let pid = IOHIDDeviceGetProperty(deviceRef, kIOHIDProductIDKey as CFString) as? Int ?? 0
        let usagePage = IOHIDDeviceGetProperty(deviceRef, kIOHIDPrimaryUsagePageKey as CFString) as? Int ?? 0
        let usage = IOHIDDeviceGetProperty(deviceRef, kIOHIDPrimaryUsageKey as CFString) as? Int ?? 0
        let maxIn = IOHIDDeviceGetProperty(deviceRef, kIOHIDMaxInputReportSizeKey as CFString) as? Int ?? 64
        let maxOut = IOHIDDeviceGetProperty(deviceRef, kIOHIDMaxOutputReportSizeKey as CFString) as? Int ?? 64

        self.vendorID = vid
        self.productID = pid
        self.primaryUsagePage = usagePage
        self.primaryUsage = usage
        self.maxInputReportSize = maxIn
        self.maxOutputReportSize = maxOut

        if vid == 21090 && pid == 19275 {
            self.kind = .keyboard
        } else if vid == 21090 && pid == 20559 {
            self.kind = .poweron
        } else {
            self.kind = .unknown
        }

        self.transport = (IOHIDDeviceGetProperty(deviceRef, kIOHIDTransportKey as CFString) as? String) ?? "USB"
        self.id = "\(vid):\(pid):\(Unmanaged.passUnretained(deviceRef).toOpaque())"

        self.inputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: inputBufferSize)
        self.inputBuffer.initialize(repeating: 0, count: inputBufferSize)
        registerInputCallback()
    }

    deinit {
        inputBuffer.deinitialize(count: inputBufferSize)
        inputBuffer.deallocate()
    }

    /// 屬性判斷：是否為支援雙向通訊的自訂 Vendor HID 介面 (Interface 3: UsagePage=1, Usage=0, MaxOutputReportSize=64)
    public var isVendorControlInterface: Bool {
        return (primaryUsagePage == 1 && primaryUsage == 0) || maxOutputReportSize >= 64
    }

    private func registerInputCallback() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(
            deviceRef,
            inputBuffer,
            inputBufferSize,
            { context, result, sender, type, reportID, report, reportLength in
                guard let context = context, result == kIOReturnSuccess, reportLength > 0 else { return }
                let this = Unmanaged<HIDDevice>.fromOpaque(context).takeUnretainedValue()
                let data = Array(UnsafeBufferPointer(start: report, count: Int(reportLength)))
                this.onInputReport?(data)
            },
            context
        )
    }

    /// 傳送 Output Report 封包
    /// - Parameters:
    ///   - data: 封包位元組陣列（首位元組為 Report ID 0x00）
    /// - Returns: 是否傳送成功
    public func sendReport(_ data: [UInt8]) -> Bool {
        guard !data.isEmpty else { return false }

        // 與 hidapi 相容：當首位元組為 Report ID 0 時將其剝離，並補齊至硬體 Output Report 長度 (64 bytes)
        let reportID = CFIndex(data[0])
        var payload = reportID == 0 ? Array(data.dropFirst()) : data
        let targetLen = max(maxOutputReportSize, 64)
        if payload.count < targetLen {
            payload.append(contentsOf: repeatElement(0, count: targetLen - payload.count))
        } else if payload.count > targetLen {
            payload = Array(payload.prefix(targetLen))
        }

        let result = IOHIDDeviceSetReport(
            deviceRef,
            kIOHIDReportTypeOutput,
            reportID,
            &payload,
            payload.count
        )
        return result == kIOReturnSuccess
    }

    /// 讀取 Input / Feature Report
    /// - Parameters:
    ///   - reportID: Report ID (通常為 0)
    ///   - expectedLength: 預期長度
    /// - Returns: 讀取到的資料位元組
    public func getReport(reportID: CFIndex = 0, expectedLength: Int = 64) -> [UInt8]? {
        var buffer = [UInt8](repeating: 0, count: expectedLength)
        var length = CFIndex(expectedLength)

        let result = IOHIDDeviceGetReport(
            deviceRef,
            kIOHIDReportTypeInput,
            reportID,
            &buffer,
            &length
        )

        guard result == kIOReturnSuccess, length > 0 else { return nil }
        return Array(buffer.prefix(Int(length)))
    }
}
