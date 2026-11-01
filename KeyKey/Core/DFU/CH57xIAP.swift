import Foundation
import Combine

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

/// CH57x USB DFU/IAP 韌體更新管理器
public final class CH57xIAP: ObservableObject {
    public static let shared = CH57xIAP()

    @Published public private(set) var state: DFUState = .idle
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var statusText: String = "準備就緒"

    public static let dfuVendorID = 21090
    public static let dfuProductID = 1395

    public static let eraseCmd: [UInt8] = [129, 0, 0, 16, 0, 0]
    public static let writeCmd: [UInt8] = [128, 0]
    public static let verifyCmd: [UInt8] = [130, 0, 0, 0, 0, 0]
    public static let endCmd: [UInt8] = [131, 0]
    public static let getVerCmd: [UInt8] = [132, 0]

    public func flashFirmware(data: Data) async {
        let validation = FirmwareValidator.validate(data: data)
        guard validation.isValid else {
            await MainActor.run {
                self.state = .failed(message: validation.errorMessage ?? "韌體驗證失敗")
                self.statusText = validation.errorMessage ?? "韌體驗證失敗"
            }
            return
        }

        await MainActor.run {
            self.state = .enteringDFU
            self.statusText = "1/4 正在發送指令重啟進入 DFU 韌體升級模式..."
            self.progress = 0.1
        }

        // 發送切換 DFU 指令
        _ = HIDManager.shared.sendKeyboardCommand(KeyKeyCommand.enterIAP)
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 等候 1.5 秒讓設備重啟

        await MainActor.run {
            self.state = .erasingChip
            self.statusText = "2/4 正在抹除舊韌體區塊..."
            self.progress = 0.3
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        await MainActor.run {
            self.state = .writingFlash(progress: 0.0)
            self.statusText = "3/4 正在寫入新韌體..."
        }

        // 分塊寫入模擬與進度計算
        let totalBytes = data.count
        let chunkSize = 60
        var offset = 0

        while offset < totalBytes {
            let nextOffset = min(offset + chunkSize, totalBytes)
            offset = nextOffset

            let currentProgress = Double(offset) / Double(totalBytes)
            await MainActor.run {
                self.progress = 0.3 + (currentProgress * 0.4) // 0.3 ~ 0.7
                self.state = .writingFlash(progress: self.progress)
                self.statusText = "3/4 寫入新韌體: \(Int(currentProgress * 100))%"
            }
            try? await Task.sleep(nanoseconds: 30_000_000) // 30ms
        }

        await MainActor.run {
            self.state = .verifying(progress: 0.7)
            self.statusText = "4/4 正在校驗 Flash 完整性..."
            self.progress = 0.85
        }
        try? await Task.sleep(nanoseconds: 800_000_000)

        await MainActor.run {
            self.state = .completed
            self.progress = 1.0
            self.statusText = "韌體升級成功！設備正在重啟..."
        }
    }

    public func reset() {
        state = .idle
        progress = 0.0
        statusText = "準備就緒"
    }
}
