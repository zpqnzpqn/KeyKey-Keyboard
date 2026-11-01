import SwiftUI

/// 現代 macOS 磨砂玻璃卡片容器
public struct FrostedCard<Content: View>: View {
    public let cornerRadius: CGFloat
    public let padding: CGFloat
    public let content: () -> Content

    public init(cornerRadius: CGFloat = 16, padding: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    public var body: some View {
        content()
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

/// 狀態藥丸標籤 (Status Badge)
public struct StatusBadge: View {
    public let isConnected: Bool
    public let connectedText: String
    public let disconnectedText: String

    public init(isConnected: Bool, connectedText: String = "已連線", disconnectedText: String = "未偵測到設備") {
        self.isConnected = isConnected
        self.connectedText = connectedText
        self.disconnectedText = disconnectedText
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? Color.green : Color.secondary.opacity(0.5))
                .frame(width: 8, height: 8)
                .shadow(color: isConnected ? Color.green.opacity(0.8) : Color.clear, radius: 4)

            Text(isConnected ? connectedText : disconnectedText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isConnected ? .primary : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(isConnected ? Color.green.opacity(0.12) : Color.secondary.opacity(0.1), in: Capsule())
    }
}
