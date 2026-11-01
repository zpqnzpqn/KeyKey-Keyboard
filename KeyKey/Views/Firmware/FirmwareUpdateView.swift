import SwiftUI
import AppKit

/// 韌體升級與驗證管理介面
public struct FirmwareUpdateView: View {
    @ObservedObject var appVM: AppViewModel
    @ObservedObject var iapVM = CH57xIAP.shared
    @State private var selectedFirmwareURL: URL? = nil
    @State private var firmwareData: Data? = nil
    @State private var validationResult: FirmwareValidationResult? = nil
    @State private var allowUnsignedFirmware: Bool = false
    @State private var showWarningAlert: Bool = false

    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }

    public var body: some View {
        VStack(spacing: 20) {
            // 目前設備版本資訊與目標選擇
            FrostedCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 16) {
                        Image(systemName: "cpu")
                            .font(.system(size: 36))
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("KeyKey 鍵盤韌體: \(appVM.deviceStatus.keyboardFirmwareVersion)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                            Text("無線開機模組韌體: \(appVM.deviceStatus.poweronFirmwareVersion)")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button {
                            appVM.queryDeviceInfo()
                        } label: {
                            Label("重新查詢", systemImage: "arrow.clockwise")
                        }
                    }

                    Divider()

                    HStack(spacing: 12) {
                        Text("選擇升級目標設備:")
                            .font(.system(size: 13, weight: .semibold))
                        Picker("升級目標設備", selection: $iapVM.targetDevice) {
                            ForEach(DFUTargetDevice.allCases) { target in
                                Text(target.rawValue).tag(target)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .onChange(of: iapVM.targetDevice) { newTarget in
                            if let data = firmwareData {
                                validationResult = FirmwareValidator.validate(
                                    data: data,
                                    fileName: selectedFirmwareURL?.lastPathComponent,
                                    target: newTarget
                                )
                            }
                        }
                    }
                }
            }

            // 韌體二進位檔案選取區
            FrostedCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("選取韌體更新檔案 (.bin)")
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                        Link(destination: URL(string: "https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE")!) {
                            Label("官方韌體發布頁 (Robit Wiki)", systemImage: "safari")
                                .font(.system(size: 12))
                        }
                        Text("·").foregroundColor(.secondary)
                        Link(destination: URL(string: "https://pan.lbtrobit.com/f/aQQfR/KeyKey_V102_%E9%98%B2%E8%AF%AF%E8%A7%A6%E7%89%88.zip")!) {
                            Label("下載 V1.0.2 防誤觸關燈版韌體", systemImage: "arrow.down.circle")
                                .font(.system(size: 12))
                        }
                    }

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

                            if let warning = result.warningMessage {
                                Text(warning)
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }

                            if result.isValid && !result.isOfficialVerified {
                                Toggle(isOn: $allowUnsignedFirmware) {
                                    Text("我了解風險，允許刷入未簽章或自訂開發者韌體")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                                .toggleStyle(.checkbox)
                                .padding(.top, 2)
                            }

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
                        if iapVM.state != .idle {
                            Button("重設狀態") {
                                iapVM.reset()
                            }
                        }
                        Spacer()
                        Button {
                            showWarningAlert = true
                        } label: {
                            Label("開始韌體更新", systemImage: "bolt.fill")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            firmwareData == nil ||
                            !(validationResult?.isValid ?? false) ||
                            (!(validationResult?.isOfficialVerified ?? false) && !allowUnsignedFirmware) ||
                            (iapVM.state != .idle && iapVM.state != .completed)
                        )
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
                        await iapVM.flashFirmware(
                            data: data,
                            fileName: selectedFirmwareURL?.lastPathComponent,
                            target: iapVM.targetDevice
                        )
                    }
                }
            }
        } message: {
            Text("即將對「\(iapVM.targetDevice.rawValue)」執行 CH57x USB IAP 燒錄。更新韌體期間請勿拔出 USB 連接線或關閉電腦。")
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
            allowUnsignedFirmware = false
            if let data = try? Data(contentsOf: url) {
                firmwareData = data
                validationResult = FirmwareValidator.validate(
                    data: data,
                    fileName: url.lastPathComponent,
                    target: iapVM.targetDevice
                )
            }
        }
    }
}
