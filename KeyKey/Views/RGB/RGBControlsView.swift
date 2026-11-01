import SwiftUI

/// RGB 燈效設定與即時選色介面
public struct RGBControlsView: View {
    @ObservedObject var appVM: AppViewModel

    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }

    public var body: some View {
        VStack(spacing: 20) {
            // 主燈光模式選擇
            mainModeSection

            Divider()

            // 子模式詳細控制
            subModeSection

            // 顏色選取區
            if shouldShowColorPicker {
                colorPickerSection
            }

            Spacer()

            Divider()

            // 儲存操作列
            HStack {
                Spacer()
                Button {
                    appVM.saveRGBConfig()
                } label: {
                    Label("儲存燈效設定至設備", systemImage: "paintbrush.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    // MARK: - 主模式選擇
    private var mainModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("燈光運作模式")
                .font(.system(size: 14, weight: .bold))

            Picker("燈光模式", selection: $appVM.rgbConfig.mainMode) {
                Text("按下亮燈 (觸發)").tag(RGBMainMode.trigger)
                Text("小夜燈模式").tag(RGBMainMode.nightlight)
                Text("手速測驗 (APM)").tag(RGBMainMode.speedTest)
                Text("完全關閉燈光").tag(RGBMainMode.lightsOff)
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - 子模式選擇
    private var subModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if appVM.rgbConfig.mainMode == .trigger {
                Text("按下觸發效果:")
                    .font(.system(size: 13, weight: .semibold))

                Picker("", selection: $appVM.rgbConfig.triggerMode) {
                    ForEach(RGBTriggerMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            } else if appVM.rgbConfig.mainMode == .nightlight {
                Text("小夜燈效果:")
                    .font(.system(size: 13, weight: .semibold))

                Picker("", selection: $appVM.rgbConfig.nightlightMode) {
                    ForEach(RGBNightlightMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            } else if appVM.rgbConfig.mainMode == .speedTest {
                HStack(spacing: 8) {
                    Image(systemName: "speedometer")
                        .foregroundColor(.accentColor)
                    Text("手速測驗模式：燈光將隨您擊鍵頻率變換反應速度。")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.secondary)
                    Text("所有 LED 燈光已關閉。")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var shouldShowColorPicker: Bool {
        if appVM.rgbConfig.mainMode == .trigger && appVM.rgbConfig.triggerMode == .customColor {
            return true
        }
        if appVM.rgbConfig.mainMode == .nightlight && (appVM.rgbConfig.nightlightMode == .customStatic || appVM.rgbConfig.nightlightMode == .customBreathing) {
            return true
        }
        return false
    }

    // MARK: - 色彩調整區
    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("自訂色彩調試")
                .font(.system(size: 14, weight: .bold))

            HStack(spacing: 20) {
                // 色塊預覽
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(appVM.rgbConfig.swiftUIColor)
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: appVM.rgbConfig.swiftUIColor.opacity(0.5), radius: 10)

                VStack(spacing: 8) {
                    // 色相滑桿
                    HStack {
                        Text("色相 (H):")
                            .font(.system(size: 12))
                            .frame(width: 65, alignment: .leading)
                        Slider(value: $appVM.rgbConfig.hue, in: 0...360)
                        Text("\(Int(appVM.rgbConfig.hue))°")
                            .font(.system(size: 12, design: .monospaced))
                            .frame(width: 40)
                    }

                    // 飽和度滑桿
                    HStack {
                        Text("飽和度 (S):")
                            .font(.system(size: 12))
                            .frame(width: 65, alignment: .leading)
                        Slider(value: $appVM.rgbConfig.saturation, in: 0...100)
                        Text("\(Int(appVM.rgbConfig.saturation))%")
                            .font(.system(size: 12, design: .monospaced))
                            .frame(width: 40)
                    }

                    // 明度滑桿
                    HStack {
                        Text("明度 (L):")
                            .font(.system(size: 12))
                            .frame(width: 65, alignment: .leading)
                        Slider(value: $appVM.rgbConfig.lightness, in: 0...100)
                        Text("\(Int(appVM.rgbConfig.lightness))%")
                            .font(.system(size: 12, design: .monospaced))
                            .frame(width: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }
}
