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

                    Text("請將 KeyKey 小鍵盤與無線開機模組同時透過 USB 連接至電腦。選擇您要作為「無線開機鍵」的實體按鍵後，點擊「開始配對模組」即可將鍵盤藍牙 MAC 寫入開機模組並完成綁定。")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)

                    HStack(spacing: 16) {
                        Text("綁定開機按鍵:")
                            .font(.system(size: 13, weight: .semibold))
                        Picker("綁定開機按鍵", selection: $appVM.powerOnPairKeyIndex) {
                            Text("按鍵 1 (Key 1)").tag(0)
                            Text("按鍵 2 (Key 2)").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 240)

                        Spacer()

                        if let mac = appVM.deviceStatus.bluetoothMac {
                            Text("鍵盤 MAC: \(mac)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(spacing: 16) {
                        Button {
                            appVM.pairPowerOnModule()
                        } label: {
                            Label("開始配對模組", systemImage: "link")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!appVM.deviceStatus.isPowerOnConnected || !appVM.deviceStatus.isKeyboardConnected)

                        Button {
                            appVM.unpairPowerOnModule()
                        } label: {
                            Label("解除配對 (支援單邊強制解綁)", systemImage: "link.badge.plus")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!appVM.deviceStatus.isPowerOnConnected && !appVM.deviceStatus.isKeyboardConnected)
                    }
                }
            }

            // 硬體協定安全提示 (VULN-03)
            FrostedCard {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("無線配對協定安全提示 (BLE MAC 綁定限制)")
                            .font(.system(size: 13, weight: .bold))
                        Text("硬體開機模組採 6-byte 藍牙 MAC 明文綁定，不包含滾動碼或對稱金鑰驗證。請勿將此模組用於無門禁管制的公共場所或高機密伺服器主機；若遺失鍵盤，可僅連接開機模組並點擊上方「解除配對」立即清除綁定。")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    Spacer()
                }
            }

            Spacer()
        }
        .padding()
    }
}
