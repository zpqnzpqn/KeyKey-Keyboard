import SwiftUI
import AppKit

/// 應用程式偏好設定與設定檔管理介面
public struct SettingsSheetView: View {
    @ObservedObject var appVM: AppViewModel
    @State private var showFactoryResetAlert: Bool = false
    @State private var pendingImportProfile: KeyKeyProfile? = nil
    @State private var importSafetyWarnings: [String] = []
    @State private var showImportWarningAlert: Bool = false

    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // 硬體連線模式與視覺化方向控制
                FrostedCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("硬體連線與安全防護 (Hardware & Security)")
                            .font(.system(size: 14, weight: .bold))

                        HStack(spacing: 14) {
                            Text("輸出模式切換:")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            Button {
                                appVM.switchToUSBMode()
                            } label: {
                                Label("切換為 USB 有線模式", systemImage: "cable.connector")
                            }
                            .disabled(!appVM.deviceStatus.isKeyboardConnected)

                            Button {
                                appVM.switchToBLEMode()
                            } label: {
                                Label("切換為 Bluetooth 藍牙模式", systemImage: "antenna.radiowaves.left.and.right")
                            }
                            .disabled(!appVM.deviceStatus.isKeyboardConnected)
                        }

                        Toggle(isOn: $appVM.swapKeyOrder) {
                            Text("比照原版硬體方向顯示（左鍵 = 按鍵 2 / index 1，右鍵 = 按鍵 1 / index 0）")
                                .font(.system(size: 13))
                        }
                        .toggleStyle(.switch)

                        Divider()

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("一鍵安全初始化 (Factory Safe Reset)")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("由於硬體韌體為 Write-Only（不支援回讀內部巨集），若鍵盤曾連接未知電腦，可一鍵強制將雙鍵覆寫回安全的預設單鍵 (Z / X) 並清除潛在隱藏巨集。")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                showFactoryResetAlert = true
                            } label: {
                                Label("一鍵安全初始化", systemImage: "shield.lefthalf.filled.badge.checkmark")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    }
                }

                // 語言設定
                FrostedCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("介面語言 (Language)")
                            .font(.system(size: 14, weight: .bold))

                        Picker("選擇語言", selection: $appVM.currentLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.radioGroup)
                    }
                }

            // 設定檔備份與匯出入
            FrostedCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("設定檔備份與共享 (Profile Management)")
                        .font(.system(size: 14, weight: .bold))

                    Text("您可以將目前按鍵自訂、巨集步進序列與 RGB 燈效匯出為單一 JSON 設定檔備份，或匯入他人分享的配置。")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineSpacing(3)

                    HStack(spacing: 16) {
                        Button {
                            exportProfile()
                        } label: {
                            Label("匯出設定檔 (.json)...", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            importProfile()
                        } label: {
                            Label("匯入設定檔...", systemImage: "square.and.arrow.down")
                        }
                    }
                }
            }

            // 軟體資訊與官方資源連結
            FrostedCard {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("KeyKey for macOS · 軟體資訊與官方資源")
                            .font(.system(size: 14, weight: .bold))
                        Text("版本 1.0.2 (Native Swift 6 & SwiftUI · 支援硬體韌體 V1.0.2)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        HStack(spacing: 14) {
                            Link(destination: URL(string: "https://github.com/zpqnzpqn/KeyKey-Keyboard")!) {
                                Label("GitHub 開源專案儲存庫", systemImage: "chevron.left.forwardslash.chevron.right")
                                    .font(.system(size: 12))
                            }

                            Link(destination: URL(string: "https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE")!) {
                                Label("原廠說明書與韌體主頁 (Robit Wiki)", systemImage: "book.pages")
                                    .font(.system(size: 12))
                            }

                            Link(destination: URL(string: "https://pan.lbtrobit.com/f/aQQfR/KeyKey_V102_%E9%98%B2%E8%AF%AF%E8%A7%A6%E7%89%88.zip")!) {
                                Label("官方 V1.0.2 防誤觸關燈版韌體下載", systemImage: "arrow.down.doc")
                                    .font(.system(size: 12))
                            }
                        }
                        .padding(.top, 2)
                    }

                    Spacer()
                }
            }

                Spacer()
            }
            .padding()
        }
        .alert("確認執行一鍵安全初始化？", isPresented: $showFactoryResetAlert) {
            Button("取消", role: .cancel) {}
            Button("確定覆寫並重設", role: .destructive) {
                appVM.factorySafeReset()
            }
        } message: {
            Text("這將把按鍵 1 與按鍵 2 強制覆寫為單鍵 Z 與 X、清除所有巨集序列，並將燈效恢復為彩虹小夜燈。")
        }
        .alert("匯入的設定檔包含高風險巨集", isPresented: $showImportWarningAlert) {
            Button("取消匯入", role: .cancel) {
                pendingImportProfile = nil
            }
            Button("了解風險，匯入並寫入硬體", role: .destructive) {
                if let profile = pendingImportProfile {
                    applyImportedProfile(profile)
                    pendingImportProfile = nil
                }
            }
        } message: {
            Text(importSafetyWarnings.joined(separator: "\n\n"))
        }
    }

    private func applyImportedProfile(_ profile: KeyKeyProfile) {
        appVM.key1Config = profile.key1Config
        appVM.key2Config = profile.key2Config
        appVM.key1Macro = profile.key1Macro
        appVM.key2Macro = profile.key2Macro
        appVM.rgbConfig = profile.rgbConfig
        appVM.applyCurrentProfileToHardware(profileName: profile.profileName)
    }

    private func exportProfile() {
        let profile = KeyKeyProfile(
            key1Config: appVM.key1Config,
            key2Config: appVM.key2Config,
            key1Macro: appVM.key1Macro,
            key2Macro: appVM.key2Macro,
            rgbConfig: appVM.rgbConfig
        )

        guard let data = try? ProfileManager.shared.exportProfile(profile) else {
            appVM.notifyToast("匯出失敗：無法編碼設定檔")
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "KeyKey_Profile.json"
        panel.prompt = "匯出"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url)
                appVM.notifyToast("設定檔已成功匯出至: \(url.lastPathComponent)")
            } catch {
                appVM.notifyToast("寫入檔案失敗: \(error.localizedDescription)")
            }
        }
    }

    private func importProfile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "匯入"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                let profile = try ProfileManager.shared.importProfile(from: data)
                let warnings = MacroSafetyAuditor.inspect(profile: profile)
                if warnings.isEmpty {
                    applyImportedProfile(profile)
                } else {
                    pendingImportProfile = profile
                    importSafetyWarnings = warnings
                    showImportWarningAlert = true
                }
            } catch {
                appVM.notifyToast("匯入失敗：檔案格式不正確")
            }
        }
    }
}
