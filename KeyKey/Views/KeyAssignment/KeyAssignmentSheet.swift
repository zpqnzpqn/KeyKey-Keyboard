import SwiftUI

/// 按鍵指派面板
public struct KeyAssignmentSheet: View {
    @ObservedObject var appVM: AppViewModel
    @State private var selectedCategory: KeyCategory = .standard
    @State private var searchText: String = ""

    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }

    private var currentConfigBinding: Binding<KeyConfig> {
        appVM.selectedKeyIndex == 0 ? $appVM.key1Config : $appVM.key2Config
    }

    public var body: some View {
        VStack(spacing: 16) {
            // 頂部修飾鍵勾選區
            modifierSelectionBar

            Divider()

            // 類別分頁切換
            Picker("按鍵類型", selection: $selectedCategory) {
                Text("標準鍵盤").tag(KeyCategory.standard)
                Text("多媒體控制").tag(KeyCategory.media)
                Text("滑鼠動作").tag(KeyCategory.mouse)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // 按鍵清單內容
            ScrollView {
                switch selectedCategory {
                case .standard:
                    standardKeysGrid
                case .media:
                    mediaKeysGrid
                case .mouse:
                    mouseActionsGrid
                default:
                    EmptyView()
                }
            }
            .frame(maxHeight: 340)

            Divider()

            // 底部儲存列
            HStack {
                Text("目前指派: \(currentConfigBinding.wrappedValue.summaryString)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    appVM.saveKeyConfig(for: appVM.selectedKeyIndex)
                } label: {
                    Label("儲存到設備", systemImage: "arrow.up.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
    }

    // MARK: - 修飾鍵勾選區
    private var modifierSelectionBar: some View {
        HStack(spacing: 16) {
            Text("修飾鍵:")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            modifierToggle(title: "Ctrl", mask: .leftCtrl)
            modifierToggle(title: "Shift", mask: .leftShift)
            modifierToggle(title: "Option (Alt)", mask: .leftAlt)
            modifierToggle(title: "Command (Win)", mask: .leftGUI)

            Spacer()

            Button("清除修飾鍵") {
                currentConfigBinding.wrappedValue.modifiers = []
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func modifierToggle(title: String, mask: ModifierMask) -> some View {
        let isChecked = currentConfigBinding.wrappedValue.modifiers.contains(mask)
        return Toggle(isOn: Binding(
            get: { isChecked },
            set: { val in
                if val {
                    currentConfigBinding.wrappedValue.modifiers.insert(mask)
                } else {
                    currentConfigBinding.wrappedValue.modifiers.remove(mask)
                }
            }
        )) {
            Text(title)
                .font(.system(size: 12, weight: isChecked ? .semibold : .regular))
        }
        .toggleStyle(.checkbox)
    }

    // MARK: - 標準鍵盤九宮格
    private var standardKeysGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 58, maximum: 72), spacing: 8)], spacing: 8) {
            ForEach(KeyDefinitions.standardKeys) { item in
                let isSelected = currentConfigBinding.wrappedValue.keyCode == item.code && currentConfigBinding.wrappedValue.type == .keyboard

                Button {
                    currentConfigBinding.wrappedValue.type = .keyboard
                    currentConfigBinding.wrappedValue.mode = .single
                    currentConfigBinding.wrappedValue.keyCode = item.code
                } label: {
                    Text(item.displayLabel)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(minWidth: 54, minHeight: 46)
                        .background(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundColor(isSelected ? .white : .primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - 多媒體鍵盤
    private var mediaKeysGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110, maximum: 140), spacing: 10)], spacing: 10) {
            ForEach(KeyDefinitions.mediaKeys) { item in
                let isSelected = currentConfigBinding.wrappedValue.keyCode == item.code &&
                    currentConfigBinding.wrappedValue.codeHigh == item.codeHigh &&
                    currentConfigBinding.wrappedValue.type == .consumer

                Button {
                    currentConfigBinding.wrappedValue.type = .consumer
                    currentConfigBinding.wrappedValue.mode = .single
                    currentConfigBinding.wrappedValue.keyCode = item.code
                    currentConfigBinding.wrappedValue.codeHigh = item.codeHigh
                } label: {
                    HStack {
                        Image(systemName: iconForMedia(item.name))
                            .font(.system(size: 14))
                        Text(item.displayLabel)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(isSelected ? .white : .primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - 滑鼠動作 (支援按鍵組合、X/Y 游標位移與滾輪)
    private var mouseActionsGrid: some View {
        let mouseOptions: [(mask: MouseButtonMask, name: String, icon: String)] = [
            (.left, "滑鼠左鍵", "computermouse"),
            (.right, "滑鼠右鍵", "computermouse.fill"),
            (.middle, "滑鼠中鍵 (滾輪點擊)", "circle.inset.filled"),
            (.sideDown, "滑鼠下側鍵 (前進)", "arrow.forward.circle"),
            (.sideUp, "滑鼠上側鍵 (後退)", "arrow.backward.circle")
        ]

        return VStack(alignment: .leading, spacing: 16) {
            Text("滑鼠按鍵 (可複選組合):")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 10)], spacing: 10) {
                ForEach(mouseOptions, id: \.mask.rawValue) { opt in
                    let isSelected = currentConfigBinding.wrappedValue.type == .mouse &&
                        currentConfigBinding.wrappedValue.mouseButtons.contains(opt.mask)

                    Button {
                        currentConfigBinding.wrappedValue.type = .mouse
                        currentConfigBinding.wrappedValue.mode = .single
                        if currentConfigBinding.wrappedValue.mouseButtons.contains(opt.mask) {
                            currentConfigBinding.wrappedValue.mouseButtons.remove(opt.mask)
                        } else {
                            currentConfigBinding.wrappedValue.mouseButtons.insert(opt.mask)
                        }
                        currentConfigBinding.wrappedValue.keyCode = currentConfigBinding.wrappedValue.mouseButtons.rawValue
                    } label: {
                        HStack {
                            Image(systemName: opt.icon)
                                .font(.system(size: 15))
                                .frame(width: 22)
                            Text(opt.name)
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 40)
                        .background(isSelected ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            HStack {
                Text("游標位移與滾輪動作 (選填):")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button("重設位移與滾輪") {
                    currentConfigBinding.wrappedValue.type = .mouse
                    currentConfigBinding.wrappedValue.mode = .single
                    currentConfigBinding.wrappedValue.mouseMoveX = 0
                    currentConfigBinding.wrappedValue.mouseMoveY = 0
                    currentConfigBinding.wrappedValue.mouseWheel = 0
                }
                .font(.system(size: 12))
            }

            HStack(spacing: 20) {
                // X 位移
                HStack(spacing: 6) {
                    Text("X 軸 (負左/正右):")
                        .font(.system(size: 12))
                    Stepper(
                        "\(currentConfigBinding.wrappedValue.mouseMoveX)",
                        value: Binding(
                            get: { Int(currentConfigBinding.wrappedValue.mouseMoveX) },
                            set: {
                                currentConfigBinding.wrappedValue.type = .mouse
                                currentConfigBinding.wrappedValue.mode = .single
                                currentConfigBinding.wrappedValue.mouseMoveX = Int8(clamping: $0)
                            }
                        ),
                        in: -127...127,
                        step: 5
                    )
                    .font(.system(size: 12, design: .monospaced))
                }

                // Y 位移
                HStack(spacing: 6) {
                    Text("Y 軸 (負上/正下):")
                        .font(.system(size: 12))
                    Stepper(
                        "\(currentConfigBinding.wrappedValue.mouseMoveY)",
                        value: Binding(
                            get: { Int(currentConfigBinding.wrappedValue.mouseMoveY) },
                            set: {
                                currentConfigBinding.wrappedValue.type = .mouse
                                currentConfigBinding.wrappedValue.mode = .single
                                currentConfigBinding.wrappedValue.mouseMoveY = Int8(clamping: $0)
                            }
                        ),
                        in: -127...127,
                        step: 5
                    )
                    .font(.system(size: 12, design: .monospaced))
                }

                // 滾輪
                HStack(spacing: 6) {
                    Text("滾輪 (正上/負下):")
                        .font(.system(size: 12))
                    Stepper(
                        "\(currentConfigBinding.wrappedValue.mouseWheel)",
                        value: Binding(
                            get: { Int(currentConfigBinding.wrappedValue.mouseWheel) },
                            set: {
                                currentConfigBinding.wrappedValue.type = .mouse
                                currentConfigBinding.wrappedValue.mode = .single
                                currentConfigBinding.wrappedValue.mouseWheel = Int8(clamping: $0)
                            }
                        ),
                        in: -127...127,
                        step: 1
                    )
                    .font(.system(size: 12, design: .monospaced))
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func iconForMedia(_ name: String) -> String {
        switch name {
        case "Mute": return "speaker.slash.fill"
        case "Volume-": return "speaker.minus.fill"
        case "Volume+": return "speaker.plus.fill"
        case "PlayPause": return "playpause.fill"
        case "PrevTrack": return "backward.fill"
        case "NextTrack": return "forward.fill"
        case "Brightness-": return "sun.min.fill"
        case "Brightness+": return "sun.max.fill"
        case "Calculator": return "candybarphone"
        case "BrowserHome": return "house.fill"
        case "Menu": return "list.bullet"
        case "BrowserBack": return "arrow.left"
        default: return "circle"
        }
    }
}
