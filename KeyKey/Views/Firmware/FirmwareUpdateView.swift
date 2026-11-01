import SwiftUI
import AppKit

/// 韌體升級與驗證管理介面
public struct FirmwareUpdateView: View {
    @ObservedObject var appVM: AppViewModel
    @ObservedObject var iapVM = CH57xIAP.shared
    @State private var selectedFirmwareURL: URL? = nil
    @State private var firmwareData: Data? = nil
    @State private var validationResult: FirmwareValidationResult? = nil
    @State private var showWarningAlert: Bool = false

    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }

    public var body: some View {
        VStack(spacing: 20) {
            // 目前設備版本資訊
            FrostedCard {
                HStack(spacing: 16) {
                    Image(systemName: "cpu")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("目前設備韌體版本")
                            .font(.system(size: 14, weight: .bold))
                        Text(appVM.deviceStatus.keyboardFirmwareVersion)
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }

                    Spacer()

                    Button {
                        appVM.queryDeviceInfo()
                    } label: {
                        Label("重新查詢", systemImage: "arrow.clockwise")
                    }
                }
            }

            // 韌體二進位檔案選取區
            FrostedCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("選取韌體更新檔案 (.bin)")
                        .font(.system(size: 14, weight: .bold))

                    HStack(spacing: 12) {
                        Button {
                            chooseFirmwareFile()
                        } label: {
                            Label("選擇韌體檔案...", systemImage: "doc.badge.plus")
                        }

                        if let url = selectedFirmwareURL {
                            Text(url.lastPathComponent)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.primary)
                        } else {
                            Text("尚未選取檔案")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    // 檔案完整性檢查資訊
                    if let result = validationResult {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: result.isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(result.isValid ? .green : .red)
                                Text(result.isValid ? "韌體驗證合格" : "韌體驗證未通過")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(result.isValid ? .green : .red)
                            }

                            Text("檔案大小: \(result.fileSize) 位元組 (bytes)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Text("SHA-256 校驗值: \(result.sha256Hex)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)

                            if let error = result.errorMessage {
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // 升級狀態與進度條
            FrostedCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("更新狀態與進度")
                        .font(.system(size: 14, weight: .bold))

                    ProgressView(value: iapVM.progress, total: 1.0)
                        .progressViewStyle(.linear)

                    Text(iapVM.statusText)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    HStack {
                        Spacer()
                        Button {
                            showWarningAlert = true
                        } label: {
                            Label("開始韌體更新", systemImage: "bolt.fill")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(firmwareData == nil || !(validationResult?.isValid ?? false) || iapVM.state != .idle)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .alert("確認更新韌體？", isPresented: $showWarningAlert) {
            Button("取消", role: .cancel) {}
            Button("確定開始更新", role: .destructive) {
                if let data = firmwareData {
                    Task {
                        await iapVM.flashFirmware(data: data)
                    }
                }
            }
        } message: {
            Text("更新韌體期間請勿拔出 USB 連接線或關閉電腦，以免設備中斷發生異常。")
        }
    }

    private func chooseFirmwareFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "選擇韌體"

        if panel.runModal() == .OK, let url = panel.url {
            selectedFirmwareURL = url
            if let data = try? Data(contentsOf: url) {
                firmwareData = data
                validationResult = FirmwareValidator.validate(data: data)
            }
        }
    }
}
