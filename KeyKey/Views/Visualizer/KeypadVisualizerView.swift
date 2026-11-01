import SwiftUI

/// 擬真雙鍵小鍵盤視覺化互動元件
public struct KeypadVisualizerView: View {
    @ObservedObject var appVM: AppViewModel
    @State private var hoveredKeyIndex: Int? = nil

    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }

    public var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // 背景動態 RGB 擴散光芒
                rgbGlowBackground

                // 小鍵盤金屬外殼底座
                keypadBaseFrame
                    .overlay(
                        HStack(spacing: 24) {
                            keycapView(index: 0, config: appVM.key1Config)
                            keycapView(index: 1, config: appVM.key2Config)
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 24)
                    )
            }
            .frame(width: 320, height: 180)

            // 鍵位快速切換與目前配置摘要
            HStack(spacing: 16) {
                keySelectButton(index: 0, title: "按鍵 1", config: appVM.key1Config)
                keySelectButton(index: 1, title: "按鍵 2", config: appVM.key2Config)
            }
        }
    }

    // MARK: - 動態光芒
    private var rgbGlowBackground: some View {
        let color = appVM.rgbConfig.swiftUIColor
        return RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(appVM.rgbConfig.mainMode == .lightsOff ? 0.0 : 0.45),
                        color.opacity(0.15),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 160
                )
            )
            .blur(radius: 20)
    }

    // MARK: - 底座外殼
    private var keypadBaseFrame: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(nsColor: .windowBackgroundColor).opacity(0.85),
                        Color(nsColor: .windowBackgroundColor).opacity(0.65)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 10)
    }

    // MARK: - 擬真機械鍵帽
    private func keycapView(index: Int, config: KeyConfig) -> some View {
        let isSelected = appVM.selectedKeyIndex == index
        let isHovered = hoveredKeyIndex == index

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appVM.selectedKeyIndex = index
            }
        } label: {
            ZStack {
                // 鍵帽陰影立體底座
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [Color.accentColor.opacity(0.9), Color.accentColor.opacity(0.7)] :
                                [Color(nsColor: .controlBackgroundColor), Color(nsColor: .controlBackgroundColor).opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                isSelected ? Color.accentColor : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.4) : Color.black.opacity(0.15), radius: isSelected ? 8 : 4, y: 3)

                VStack(spacing: 4) {
                    Text("KEY \(index + 1)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)

                    Text(config.summaryString)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 6)
                }
            }
            .frame(width: 100, height: 90)
            .scaleEffect(isHovered ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredKeyIndex = hovering ? index : nil
        }
    }

    private func keySelectButton(index: Int, title: String, config: KeyConfig) -> some View {
        let isSelected = appVM.selectedKeyIndex == index
        return Button {
            withAnimation {
                appVM.selectedKeyIndex = index
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                Text("\(title): \(config.summaryString)")
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
