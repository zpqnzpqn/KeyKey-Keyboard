import SwiftUI
import AppKit

/// 應用程式偏好設定與設定檔管理介面
public struct SettingsSheetView: View {
    @ObservedObject var appVM: AppViewModel

    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }

    public var body: some View {
        VStack(spacing: 20) {
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

            // 軟體資訊
            FrostedCard {
                HStack(spacing: 16) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("KeyKey for macOS")
                            .font(.system(size: 14, weight: .bold))
                        Text("版本 1.0.0 (Native Swift 6 & SwiftUI)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Link("GitHub 開源專案儲存庫", destination: URL(string: "https://github.com/zpqnzpqn/KeyKey-Keyboard")!)
                            .font(.system(size: 12))
                    }

                    Spacer()
                }
            }

            Spacer()
        }
        .padding()
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
                appVM.key1Config = profile.key1Config
                appVM.key2Config = profile.key2Config
                appVM.key1Macro = profile.key1Macro
                appVM.key2Macro = profile.key2Macro
                appVM.rgbConfig = profile.rgbConfig
                appVM.notifyToast("已成功匯入設定檔: \(profile.profileName)")
            } catch {
                appVM.notifyToast("匯入失敗：檔案格式不正確")
            }
        }
    }
}
