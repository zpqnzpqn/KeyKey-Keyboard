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
    public let kind: DeviceKind
    public let transport: String

    public init(deviceRef: IOHIDDevice) {
        self.deviceRef = deviceRef

        let vid = IOHIDDeviceGetProperty(deviceRef, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let pid = IOHIDDeviceGetProperty(deviceRef, kIOHIDProductIDKey as CFString) as? Int ?? 0
        self.vendorID = vid
        self.productID = pid

        if vid == 21090 && pid == 19275 {
            self.kind = .keyboard
        } else if vid == 21090 && pid == 20559 {
            self.kind = .poweron
        } else {
            self.kind = .unknown
        }

        self.transport = (IOHIDDeviceGetProperty(deviceRef, kIOHIDTransportKey as CFString) as? String) ?? "USB"
        self.id = "\(vid):\(pid):\(Unmanaged.passUnretained(deviceRef).toOpaque())"
    }

    /// 傳送 Output Report 封包
    /// - Parameters:
    ///   - data: 封包位元組陣列（首位元組為 Report ID）
    /// - Returns: 是否傳送成功
    public func sendReport(_ data: [UInt8]) -> Bool {
        guard !data.isEmpty else { return false }
        var buffer = data
        let reportID = CFIndex(buffer[0])

        let result = IOHIDDeviceSetReport(
            deviceRef,
            kIOHIDReportTypeOutput,
            reportID,
            &buffer,
            buffer.count
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
