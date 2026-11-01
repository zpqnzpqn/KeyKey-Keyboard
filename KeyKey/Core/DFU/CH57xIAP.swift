import Foundation
import Combine
import IOKit
import IOKit.usb
import IOKit.usb.IOUSBLib

public enum DFUState: Equatable {
    case idle
    case enteringDFU
    case waitingForDevice
    case erasingChip
    case writingFlash(progress: Double)
    case verifying(progress: Double)
    case completed
    case failed(message: String)
}

/// CH57x USB DFU/IAP 韌體更新管理器 (依據原版 ch57xIAP.py 逆向協定實作)
public final class CH57xIAP: ObservableObject {
    public static let shared = CH57xIAP()

    @Published public private(set) var state: DFUState = .idle
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var statusText: String = "準備就緒"
    @Published public var targetDevice: DFUTargetDevice = .keyboard

    // WCH CH57x Bootloader USB IDs 與端點
    public static let dfuVendorID = 21090  // 0x5262
    public static let dfuProductID = 1395  // 0x0573
    public static let epOutAddr: UInt8 = 0x02
    public static let epInAddr: UInt8 = 0x82
    public static let maxPacketLen = 64

    // IAP 命令常數
    public static let eraseCmd: [UInt8] = [0x81, 0x00, 0x00, 0x10, 0x00, 0x00]
    public static let writeCmdPrefix: UInt8 = 0x80
    public static let writeEndCmd: [UInt8] = [0x80, 0x00]
    public static let verifyCmdPrefix: UInt8 = 0x82
    public static let endCmd: [UInt8] = [0x83, 0x00]
    public static let getVerCmd: [UInt8] = [0x84, 0x00]

    public func flashFirmware(data: Data, fileName: String? = nil, target: DFUTargetDevice? = nil) async {
        let activeTarget = target ?? targetDevice
        let validation = FirmwareValidator.validate(data: data, fileName: fileName, target: activeTarget)
        guard validation.isValid else {
            await MainActor.run {
                self.state = .failed(message: validation.errorMessage ?? "韌體驗證失敗")
                self.statusText = validation.errorMessage ?? "韌體驗證失敗"
            }
            return
        }

        await MainActor.run {
            self.state = .enteringDFU
            self.statusText = "1/5 正在發送指令重啟「\(activeTarget.rawValue)」進入 IAP 升級模式..."
            self.progress = 0.05
        }

        // 若設備尚未處於 DFU 模式，先透過 HID 發送 enterIAP 指令
        if !Self.isDFUDevicePresent() {
            let sent: Bool
            switch activeTarget {
            case .keyboard:
                sent = HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.enterIAP)
            case .powerOn:
                sent = HIDManager.shared.sendPowerOnCommand(KeyKeyCommand.enterIAP)
            }
            if !sent {
                await MainActor.run {
                    self.state = .failed(message: "無法發送進入 DFU 指令，請確認「\(activeTarget.rawValue)」已透過 USB 連接。")
                    self.statusText = "失敗：目標設備未連線"
                }
                return
            }
        }

        await MainActor.run {
            self.state = .waitingForDevice
            self.statusText = "2/5 等待 CH57x IAP Bootloader (VID: 0x5262, PID: 0x0573) 連線..."
            self.progress = 0.12
        }

        // 等候最多 6 秒讓 USB DFU 裝置重列舉
        var session: CH57xUSBSession? = nil
        for _ in 0..<24 {
            try? await Task.sleep(nanoseconds: 250_000_000)
            if let opened = CH57xUSBSession.open(vendorID: Self.dfuVendorID, productID: Self.dfuProductID) {
                session = opened
                break
            }
        }

        guard let usb = session else {
            await MainActor.run {
                self.state = .failed(message: "找不到 CH57x IAP 設備 (0x5262:0x0573)，請重插 USB 後再試。")
                self.statusText = "失敗：等待 DFU Bootloader 逾時"
            }
            return
        }
        defer { usb.close() }

        // Step 1: 讀取 IAP 版本 (0x84, 0x00)
        guard let verResp = usb.transfer(outBytes: Self.getVerCmd, readLength: 2), verResp.count >= 2 else {
            await MainActor.run {
                self.state = .failed(message: "讀取 Bootloader 版本失敗")
                self.statusText = "失敗：Bootloader 無回應"
            }
            return
        }

        // Step 2: 抹除 Flash (0x81, 0x00, 0x00, 0x10, 0x00, 0x00)
        await MainActor.run {
            self.state = .erasingChip
            self.statusText = "3/5 正在抹除舊韌體區塊 (Bootloader v\(verResp[0]))..."
            self.progress = 0.20
        }

        guard let eraseResp = usb.transfer(outBytes: Self.eraseCmd, readLength: 2),
              eraseResp.count >= 2, eraseResp[0] == 0, eraseResp[1] == 0 else {
            await MainActor.run {
                self.state = .failed(message: "抹除晶片 Flash 失敗")
                self.statusText = "失敗：抹除晶片時發生錯誤"
            }
            return
        }

        // Step 3: 分塊寫入 Flash (每筆最大 62 bytes payload, 標頭 [0x80, len])
        let firmwareBytes = [UInt8](data)
        let totalBytes = firmwareBytes.count
        let writeChunkSize = Self.maxPacketLen - 2 // 62 bytes
        var currAddr = 0

        await MainActor.run {
            self.state = .writingFlash(progress: 0.25)
            self.statusText = "4/5 正在寫入新韌體..."
        }

        while currAddr < totalBytes {
            let pktLen = min(writeChunkSize, totalBytes - currAddr)
            var packet = [UInt8](repeating: 0, count: 2 + pktLen)
            packet[0] = Self.writeCmdPrefix
            packet[1] = UInt8(pktLen)
            for i in 0..<pktLen {
                packet[2 + i] = firmwareBytes[currAddr + i]
            }

            guard let writeResp = usb.transfer(outBytes: packet, readLength: 2),
                  writeResp.count >= 2, writeResp[0] == 0, writeResp[1] == 0 else {
                let failAddr = currAddr
                await MainActor.run {
                    self.state = .failed(message: "寫入 Flash 位址 0x\(String(format: "%04X", failAddr)) 失敗")
                    self.statusText = "失敗：寫入韌體中斷"
                }
                return
            }

            currAddr += pktLen
            let writtenBytes = currAddr
            let ratio = Double(writtenBytes) / Double(totalBytes)
            await MainActor.run {
                self.progress = 0.25 + (ratio * 0.40) // 0.25 ~ 0.65
                self.state = .writingFlash(progress: self.progress)
                self.statusText = "4/5 正在寫入新韌體: \(Int(ratio * 100))% (\(writtenBytes)/\(totalBytes) bytes)"
            }
        }

        // 寫入結束指令 [0x80, 0x00]
        guard let writeEndResp = usb.transfer(outBytes: Self.writeEndCmd, readLength: 2),
              writeEndResp.count >= 2, writeEndResp[0] == 0, writeEndResp[1] == 0 else {
            await MainActor.run {
                self.state = .failed(message: "寫入結束確認指令 (WRITE_CMD_END) 失敗")
                self.statusText = "失敗：寫入結束確認異常"
            }
            return
        }

        // Step 4: 分塊校驗 Flash (每筆最大 56 bytes payload, 標頭 [0x82, len, addrLE(4)], 起始偏移 0x1000)
        let verifyChunkSize = Self.maxPacketLen - 8 // 56 bytes
        currAddr = 0

        await MainActor.run {
            self.state = .verifying(progress: 0.65)
            self.statusText = "5/5 正在校驗 Flash 完整性..."
        }

        while currAddr < totalBytes {
            let pktLen = min(verifyChunkSize, totalBytes - currAddr)
            let flashAddr = UInt32(currAddr + 0x1000)
            var packet = [UInt8](repeating: 0, count: 6 + pktLen)
            packet[0] = Self.verifyCmdPrefix
            packet[1] = UInt8(pktLen)
            packet[2] = UInt8(flashAddr & 0xFF)
            packet[3] = UInt8((flashAddr >> 8) & 0xFF)
            packet[4] = UInt8((flashAddr >> 16) & 0xFF)
            packet[5] = UInt8((flashAddr >> 24) & 0xFF)
            for i in 0..<pktLen {
                packet[6 + i] = firmwareBytes[currAddr + i]
            }

            guard let verifyResp = usb.transfer(outBytes: packet, readLength: 2),
                  verifyResp.count >= 2, verifyResp[0] == 0, verifyResp[1] == 0 else {
                await MainActor.run {
                    self.state = .failed(message: "校驗 Flash 位址 0x\(String(format: "%04X", flashAddr)) 不符")
                    self.statusText = "失敗：Flash 校驗未通過"
                }
                return
            }

            currAddr += pktLen
            let ratio = Double(currAddr) / Double(totalBytes)
            await MainActor.run {
                self.progress = 0.65 + (ratio * 0.30) // 0.65 ~ 0.95
                self.state = .verifying(progress: self.progress)
                self.statusText = "5/5 正在校驗 Flash 完整性: \(Int(ratio * 100))%"
            }
        }

        // Step 5: 發送結束指令 [0x83, 0x00] 重啟回正常模式
        _ = usb.writeOnly(outBytes: Self.endCmd)

        await MainActor.run {
            self.state = .completed
            self.progress = 1.0
            self.statusText = "韌體升級成功！設備已重啟回到正常運作模式。"
        }
    }

    public func reset() {
        state = .idle
        progress = 0.0
        statusText = "準備就緒"
    }

    public static func isDFUDevicePresent() -> Bool {
        guard let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary? else {
            return false
        }
        matchingDict[kUSBVendorID] = NSNumber(value: dfuVendorID)
        matchingDict[kUSBProductID] = NSNumber(value: dfuProductID)
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matchingDict)
        if service != 0 {
            IOObjectRelease(service)
            return true
        }
        return false
    }
}

// MARK: - macOS IOKit USB Bulk 通訊封裝 (0x5262:0x0573, EP_OUT=0x02, EP_IN=0x82)
private final class CH57xUSBSession {
    private var deviceInterfacePtr: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>?
    private var interfaceInterfacePtr: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface>?>?
    private var outPipeRef: UInt8 = 0
    private var inPipeRef: UInt8 = 0

    static func open(vendorID: Int, productID: Int) -> CH57xUSBSession? {
        guard let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary? else {
            return nil
        }
        matchingDict[kUSBVendorID] = NSNumber(value: vendorID)
        matchingDict[kUSBProductID] = NSNumber(value: productID)

        let usbDevice = IOServiceGetMatchingService(kIOMainPortDefault, matchingDict)
        guard usbDevice != 0 else { return nil }
        defer { IOObjectRelease(usbDevice) }

        let kIOUSBDeviceUserClientTypeID = CFUUIDGetConstantUUIDWithBytes(
            nil,
            0x9D, 0xC7, 0xB7, 0x80, 0x9E, 0xC0, 0x11, 0xD4,
            0xA5, 0x4F, 0x00, 0x0A, 0x27, 0x05, 0x28, 0x61
        )
        let kIOCFPlugInInterfaceID = CFUUIDGetConstantUUIDWithBytes(
            nil,
            0xC2, 0x44, 0xE8, 0x58, 0x10, 0x9C, 0x11, 0xD4,
            0x91, 0xD4, 0x00, 0x50, 0xE4, 0xC6, 0x42, 0x6F
        )
        let kIOUSBDeviceInterfaceID = CFUUIDGetConstantUUIDWithBytes(
            nil,
            0x5C, 0x81, 0x87, 0xD0, 0x9E, 0xF3, 0x11, 0xD4,
            0x8B, 0x45, 0x00, 0x0A, 0x27, 0x05, 0x28, 0x61
        )

        var plugInPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
        var score: Int32 = 0
        let kr = IOCreatePlugInInterfaceForService(
            usbDevice,
            kIOUSBDeviceUserClientTypeID,
            kIOCFPlugInInterfaceID,
            &plugInPtr,
            &score
        )
        guard kr == kIOReturnSuccess, let plugIn = plugInPtr, let plugInVTable = plugIn.pointee?.pointee else {
            return nil
        }
        defer { _ = plugInVTable.Release(plugIn) }

        var devRawPtr: UnsafeMutableRawPointer?
        let qRes = plugInVTable.QueryInterface(
            plugIn,
            CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
            &devRawPtr
        )
        guard qRes == S_OK, let devRaw = devRawPtr else { return nil }
        let devPtr = devRaw.assumingMemoryBound(to: UnsafeMutablePointer<IOUSBDeviceInterface>?.self)
        guard let devVTable = devPtr.pointee?.pointee else { return nil }

        guard devVTable.USBDeviceOpen(devPtr) == kIOReturnSuccess else {
            _ = devVTable.Release(devPtr)
            return nil
        }

        // 設定第一組 Configuration
        var configDesc: IOUSBConfigurationDescriptorPtr?
        if devVTable.GetConfigurationDescriptorPtr(devPtr, 0, &configDesc) == kIOReturnSuccess,
           let cfg = configDesc {
            _ = devVTable.SetConfiguration(devPtr, cfg.pointee.bConfigurationValue)
        }

        // 尋找第一個 USB Interface
        var request = IOUSBFindInterfaceRequest(
            bInterfaceClass: UInt16(kIOUSBFindInterfaceDontCare),
            bInterfaceSubClass: UInt16(kIOUSBFindInterfaceDontCare),
            bInterfaceProtocol: UInt16(kIOUSBFindInterfaceDontCare),
            bAlternateSetting: UInt16(kIOUSBFindInterfaceDontCare)
        )
        var iterator: io_iterator_t = 0
        guard devVTable.CreateInterfaceIterator(devPtr, &request, &iterator) == kIOReturnSuccess else {
            _ = devVTable.USBDeviceClose(devPtr)
            _ = devVTable.Release(devPtr)
            return nil
        }
        defer { IOObjectRelease(iterator) }

        let usbInterface = IOIteratorNext(iterator)
        guard usbInterface != 0 else {
            _ = devVTable.USBDeviceClose(devPtr)
            _ = devVTable.Release(devPtr)
            return nil
        }
        defer { IOObjectRelease(usbInterface) }

        let kIOUSBInterfaceUserClientTypeID = CFUUIDGetConstantUUIDWithBytes(
            nil,
            0x2D, 0x97, 0x86, 0xC6, 0x9E, 0xF3, 0x11, 0xD4,
            0xAD, 0x51, 0x00, 0x0A, 0x27, 0x05, 0x28, 0x61
        )
        let kIOUSBInterfaceInterfaceID = CFUUIDGetConstantUUIDWithBytes(
            nil,
            0x73, 0xC9, 0x7A, 0xE8, 0x9E, 0xF3, 0x11, 0xD4,
            0xB1, 0xD0, 0x00, 0x0A, 0x27, 0x05, 0x28, 0x61
        )

        var intfPlugInPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
        var intfScore: Int32 = 0
        guard IOCreatePlugInInterfaceForService(
            usbInterface,
            kIOUSBInterfaceUserClientTypeID,
            kIOCFPlugInInterfaceID,
            &intfPlugInPtr,
            &intfScore
        ) == kIOReturnSuccess,
        let intfPlugIn = intfPlugInPtr,
        let intfPlugInVTable = intfPlugIn.pointee?.pointee else {
            _ = devVTable.USBDeviceClose(devPtr)
            _ = devVTable.Release(devPtr)
            return nil
        }
        defer { _ = intfPlugInVTable.Release(intfPlugIn) }

        var intfRawPtr: UnsafeMutableRawPointer?
        guard intfPlugInVTable.QueryInterface(
            intfPlugIn,
            CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
            &intfRawPtr
        ) == S_OK, let intfRaw = intfRawPtr else {
            _ = devVTable.USBDeviceClose(devPtr)
            _ = devVTable.Release(devPtr)
            return nil
        }

        let intfPtr = intfRaw.assumingMemoryBound(to: UnsafeMutablePointer<IOUSBInterfaceInterface>?.self)
        guard let intfVTable = intfPtr.pointee?.pointee,
              intfVTable.USBInterfaceOpen(intfPtr) == kIOReturnSuccess else {
            _ = devVTable.USBDeviceClose(devPtr)
            _ = devVTable.Release(devPtr)
            return nil
        }

        var numEndpoints: UInt8 = 0
        _ = intfVTable.GetNumEndpoints(intfPtr, &numEndpoints)

        var foundOutPipe: UInt8 = 0
        var foundInPipe: UInt8 = 0

        if numEndpoints >= 1 {
            for pipeIdx in 1...numEndpoints {
                var direction: UInt8 = 0
                var number: UInt8 = 0
                var transferType: UInt8 = 0
                var maxPacketSize: UInt16 = 0
                var interval: UInt8 = 0
                if intfVTable.GetPipeProperties(intfPtr, pipeIdx, &direction, &number, &transferType, &maxPacketSize, &interval) == kIOReturnSuccess {
                    if direction == kUSBOut && (number == 2 || foundOutPipe == 0) {
                        foundOutPipe = pipeIdx
                    } else if direction == kUSBIn && (number == 2 || foundInPipe == 0) {
                        foundInPipe = pipeIdx
                    }
                }
            }
        }

        guard foundOutPipe != 0 && foundInPipe != 0 else {
            _ = intfVTable.USBInterfaceClose(intfPtr)
            _ = intfVTable.Release(intfPtr)
            _ = devVTable.USBDeviceClose(devPtr)
            _ = devVTable.Release(devPtr)
            return nil
        }

        let session = CH57xUSBSession()
        session.deviceInterfacePtr = devPtr
        session.interfaceInterfacePtr = intfPtr
        session.outPipeRef = foundOutPipe
        session.inPipeRef = foundInPipe
        return session
    }

    func writeOnly(outBytes: [UInt8]) -> Bool {
        guard let intfPtr = interfaceInterfacePtr,
              let intfVTable = intfPtr.pointee?.pointee else { return false }
        var buf = outBytes
        let kr = buf.withUnsafeMutableBytes { rawBuf in
            intfVTable.WritePipe(intfPtr, outPipeRef, rawBuf.baseAddress, UInt32(rawBuf.count))
        }
        return kr == kIOReturnSuccess
    }

    func transfer(outBytes: [UInt8], readLength: Int) -> [UInt8]? {
        guard let intfPtr = interfaceInterfacePtr,
              let intfVTable = intfPtr.pointee?.pointee else { return nil }
        guard writeOnly(outBytes: outBytes) else { return nil }

        var readBuf = [UInt8](repeating: 0, count: max(readLength, 64))
        var actualCount = UInt32(readBuf.count)
        let kr = readBuf.withUnsafeMutableBytes { rawBuf in
            intfVTable.ReadPipe(intfPtr, inPipeRef, rawBuf.baseAddress, &actualCount)
        }
        guard kr == kIOReturnSuccess else { return nil }
        return Array(readBuf.prefix(Int(actualCount)))
    }

    func close() {
        if let intfPtr = interfaceInterfacePtr, let intfVTable = intfPtr.pointee?.pointee {
            _ = intfVTable.USBInterfaceClose(intfPtr)
            _ = intfVTable.Release(intfPtr)
            interfaceInterfacePtr = nil
        }
        if let devPtr = deviceInterfacePtr, let devVTable = devPtr.pointee?.pointee {
            _ = devVTable.USBDeviceClose(devPtr)
            _ = devVTable.Release(devPtr)
            deviceInterfacePtr = nil
        }
    }
}
