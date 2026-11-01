import SwiftUI

/// 無線開機模組管理介面
public struct PowerOnModuleView: View {
    @ObservedObject var appVM: AppViewModel

    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }

    public var body: some View {
        VStack(spacing: 20) {
            // 模組狀態卡片
            FrostedCard {
                HStack(spacing: 16) {
                    Image(systemName: "power.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(appVM.deviceStatus.isPowerOnConnected ? .green : .secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("無線遠端開機模組 (PowerOnMod)")
                            .font(.system(size: 16, weight: .bold))

                        HStack(spacing: 12) {
                            StatusBadge(
                                isConnected: appVM.deviceStatus.isPowerOnConnected,
                                connectedText: "模組已連線",
                                disconnectedText: "模組未連線"
                            )

                            Text("韌體版本: \(appVM.deviceStatus.poweronFirmwareVersion)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
            }

            // 配對操作說明與按鈕
            FrostedCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("模組無線配對操作")
                        .font(.system(size: 14, weight: .bold))

                    Text("請先將 KeyKey 小鍵盤連接至電腦，並將無線開機模組接上電源。點擊下方「開始配對」按鈕後，模組 LED 燈將閃爍進入對頻模式。")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)

                    HStack(spacing: 16) {
                        Button {
                            appVM.pairPowerOnModule()
                        } label: {
                            Label("開始配對模組", systemImage: "link")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!appVM.deviceStatus.isPowerOnConnected && !appVM.deviceStatus.isKeyboardConnected)

                        Button {
                            appVM.unpairPowerOnModule()
                        } label: {
                            Label("解除配對", systemImage: "link.badge.plus")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!appVM.deviceStatus.isPowerOnConnected && !appVM.deviceStatus.isKeyboardConnected)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}
