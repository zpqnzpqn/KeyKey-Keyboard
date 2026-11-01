import SwiftUI

/// 按鍵即時測試與點擊次數計數板
public struct KeyInputTesterView: View {
    @ObservedObject var appVM: AppViewModel
    @State private var inputTestBuffer: String = ""

    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }

    public var body: some View {
        VStack(spacing: 20) {
            // 頂部統計指標
            HStack(spacing: 20) {
                FrostedCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("累計擊鍵次數")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("\(appVM.keyTestCount)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.accentColor)
                    }
                    .frame(minWidth: 140, alignment: .leading)
                }

                FrostedCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("測試提示")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("在此測試您剛自訂的鍵位或巨集輸出是否如預期。")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // 即時輸入測試框
            FrostedCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("即時字元測試輸入框 (點擊聚焦敲擊鍵盤):")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Button("清空字元") {
                            inputTestBuffer = ""
                        }
                        .font(.system(size: 12))
                    }

                    TextField("請在此直接按下 KeyKey 小鍵盤...", text: $inputTestBuffer)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 15, design: .monospaced))
                        .onChange(of: inputTestBuffer) { val in
                            if let lastChar = val.last {
                                appVM.recordTestKey(name: String(lastChar))
                            }
                        }
                }
            }

            // 擊鍵事件日誌清單
            FrostedCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("擊鍵日誌 (即時抓取):")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Button("清除日誌") {
                            appVM.clearTestLogs()
                        }
                        .font(.system(size: 12))
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            if appVM.keyTestLogs.isEmpty {
                                Text("尚無擊鍵記錄...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, minHeight: 120)
                            } else {
                                ForEach(appVM.keyTestLogs, id: \.self) { log in
                                    Text(log)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 140)
                }
            }

            Spacer()
        }
        .padding()
    }
}
