import Foundation

/// 設備連線與硬體狀態模型
public struct DeviceStatus: Codable, Equatable {
    public var isKeyboardConnected: Bool = false
    public var isPowerOnConnected: Bool = false
    public var keyboardFirmwareVersion: String = "未偵測"
    public var poweronFirmwareVersion: String = "未偵測"
    public var batteryLevel: Int? = nil
    public var bluetoothMac: String? = nil
    public var macBytes: [UInt8] = []
    public var activeLayer: UInt8 = 0

    public init(
        isKeyboardConnected: Bool = false,
        isPowerOnConnected: Bool = false,
        keyboardFirmwareVersion: String = "未偵測",
        poweronFirmwareVersion: String = "未偵測",
        batteryLevel: Int? = nil,
        bluetoothMac: String? = nil,
        macBytes: [UInt8] = [],
        activeLayer: UInt8 = 0
    ) {
        self.isKeyboardConnected = isKeyboardConnected
        self.isPowerOnConnected = isPowerOnConnected
        self.keyboardFirmwareVersion = keyboardFirmwareVersion
        self.poweronFirmwareVersion = poweronFirmwareVersion
        self.batteryLevel = batteryLevel
        self.bluetoothMac = bluetoothMac
        self.macBytes = macBytes
        self.activeLayer = activeLayer
    }
}
