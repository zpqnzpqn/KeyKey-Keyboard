import SwiftUI

/// 主視窗介面 (現代 macOS 原生磨砂玻璃架構)
public struct MainView: View {
    @StateObject private var appVM = AppViewModel()

    public init() {}

    public var body: some View {
        NavigationSplitView {
            // 側邊欄導航清單
            List(AppViewModel.NavigationTab.allCases, selection: $appVM.selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.iconName)
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
            .safeAreaInset(edge: .bottom) {
                // 側邊欄底部硬體連線狀態
                sidebarBottomStatus
            }
        } detail: {
            // 內容區
            VStack(spacing: 0) {
                // 上半部：始終呈現的擬真雙鍵視覺化區 (除特定全幅分頁外)
                if shouldShowVisualizer {
                    KeypadVisualizerView(appVM: appVM)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    Divider()
                }

                // 下半部：各功能分頁內容
                detailContentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(
                // 現代 macOS 原生玻璃霧面層次
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            )
            .overlay(alignment: .top) {
                // Toast 浮動狀態通知
                if appVM.showToast, let msg = appVM.toastMessage {
                    toastBanner(message: msg)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: 10) {
                        StatusBadge(
                            isConnected: appVM.deviceStatus.isKeyboardConnected,
                            connectedText: "KeyKey 已連線 (\(appVM.deviceStatus.keyboardFirmwareVersion))",
                            disconnectedText: "未偵測到鍵盤"
                        )

                        if let battery = appVM.deviceStatus.batteryLevel {
                            HStack(spacing: 4) {
                                Image(systemName: battery >= 80 ? "battery.100" : (battery >= 40 ? "battery.50" : "battery.25"))
                                    .foregroundColor(battery > 20 ? .green : .orange)
                                Text("\(battery)%")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1), in: Capsule())
                        }
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button {
                        appVM.queryDeviceInfo()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("重新查詢設備狀態 (韌體版本、電量與藍牙 MAC)")
                }
            }
        }
        .environment(\.locale, appVM.currentLanguage.locale)
        .frame(minWidth: 840, minHeight: 620)
    }

    private var shouldShowVisualizer: Bool {
        appVM.selectedTab == .keypad || appVM.selectedTab == .macro || appVM.selectedTab == .rgb
    }

    @ViewBuilder
    private var detailContentView: some View {
        switch appVM.selectedTab {
        case .keypad:
            KeyAssignmentSheet(appVM: appVM)
        case .macro:
            MacroEditorView(appVM: appVM)
        case .rgb:
            RGBControlsView(appVM: appVM)
        case .powerOn:
            PowerOnModuleView(appVM: appVM)
        case .tester:
            KeyInputTesterView(appVM: appVM)
        case .firmware:
            FirmwareUpdateView(appVM: appVM)
        case .settings:
            SettingsSheetView(appVM: appVM)
        }
    }

    private var sidebarBottomStatus: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            HStack {
                Circle()
                    .fill(appVM.deviceStatus.isKeyboardConnected ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                Text(appVM.deviceStatus.isKeyboardConnected ? "設備通訊正常 (\(appVM.deviceStatus.keyboardFirmwareVersion))" : "等待連線中...")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            if let mac = appVM.deviceStatus.bluetoothMac {
                Text("BLE MAC: \(mac)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func toastBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .overlay(
            Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
        .padding(.top, 14)
    }
}
