import SwiftUI

/// 巨集序列編輯器與即時錄製介面
public struct MacroEditorView: View {
    @ObservedObject var appVM: AppViewModel
    @State private var loopSelection: Int = 0 // 0: 無限, 1: 按住循環, 2: 指定次數
    @State private var loopCountValue: Int = 10
    @State private var safetyWarnings: [String] = []
    @State private var showSafetyAlert: Bool = false

    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }

    private var currentMacroBinding: Binding<MacroConfig> {
        appVM.selectedKeyIndex == 0 ? $appVM.key1Macro : $appVM.key2Macro
    }

    private var maxStepCount: Int {
        currentMacroBinding.wrappedValue.type == .mouse ? 8 : 14
    }

    public var body: some View {
        VStack(spacing: 16) {
            // 頂部控制列：目標鍵位、巨集類型與即時錄製
            topControlBar

            Divider()

            // 循環模式選擇區
            loopModeBar

            // 巨集步驟清單
            stepsListView

            Divider()

            // 底部操作列
            bottomActionBar
        }
        .padding()
        .onAppear {
            syncLoopUI(from: currentMacroBinding.wrappedValue.loopMode)
        }
        .onChange(of: appVM.selectedKeyIndex) { _ in
            syncLoopUI(from: currentMacroBinding.wrappedValue.loopMode)
        }
    }

    private func syncLoopUI(from mode: MacroLoopMode) {
        switch mode {
        case .infinite:
            loopSelection = 0
        case .holdToLoop:
            loopSelection = 1
        case .count(let c):
            loopSelection = 2
            loopCountValue = max(1, min(250, c))
        }
    }

    // MARK: - 頂部控制列
    private var topControlBar: some View {
        HStack(spacing: 16) {
            Text("編輯目標：按鍵 \(appVM.selectedKeyIndex + 1)")
                .font(.system(size: 15, weight: .bold))

            Picker("巨集類型", selection: currentMacroBinding.type) {
                Text("鍵盤巨集 (最多14步)").tag(KeyType.keyboard)
                Text("滑鼠巨集 (最多8步)").tag(KeyType.mouse)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 260)

            Spacer()

            // 即時按鍵錄製開關 (僅於鍵盤巨集模式啟用)
            if currentMacroBinding.wrappedValue.type == .keyboard {
                if appVM.isRecordingMacro {
                    Button {
                        appVM.stopMacroRecording()
                    } label: {
                        Label("停止錄製", systemImage: "stop.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        appVM.startMacroRecording()
                    } label: {
                        Label("即時錄製按鍵", systemImage: "record.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - 循環模式
    private var loopModeBar: some View {
        HStack(spacing: 20) {
            Text("循環模式:")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            Picker("", selection: $loopSelection) {
                Text("無限循環").tag(0)
                Text("按住循環").tag(1)
                Text("指定次數").tag(2)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)
            .onChange(of: loopSelection) { val in
                if val == 0 {
                    currentMacroBinding.wrappedValue.loopMode = .infinite
                } else if val == 1 {
                    currentMacroBinding.wrappedValue.loopMode = .holdToLoop
                } else {
                    currentMacroBinding.wrappedValue.loopMode = .count(loopCountValue)
                }
            }

            if loopSelection == 2 {
                Stepper("次數: \(loopCountValue)", value: $loopCountValue, in: 1...250)
                    .font(.system(size: 12))
                    .onChange(of: loopCountValue) { val in
                        currentMacroBinding.wrappedValue.loopMode = .count(val)
                    }
            }

            Spacer()
        }
    }

    // MARK: - 步驟清單
    private var stepsListView: some View {
        ScrollView {
            VStack(spacing: 10) {
                if currentMacroBinding.wrappedValue.steps.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("尚未建立步驟，點擊下方「新增步驟」或使用「即時錄製」")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    ForEach(Array(currentMacroBinding.wrappedValue.steps.indices), id: \.self) { idx in
                        stepRow(index: idx)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(minHeight: 220)
    }

    private func stepRow(index: Int) -> some View {
        let step = currentMacroBinding.wrappedValue.steps[index]
        let isMouse = currentMacroBinding.wrappedValue.type == .mouse

        return HStack(spacing: 10) {
            // 序號
            Text("#\(index + 1)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 28)

            if isMouse {
                // 滑鼠巨集步驟編輯器
                Menu {
                    mouseMaskToggleItem(index: index, title: "左鍵", mask: .left)
                    mouseMaskToggleItem(index: index, title: "右鍵", mask: .right)
                    mouseMaskToggleItem(index: index, title: "中鍵", mask: .middle)
                    mouseMaskToggleItem(index: index, title: "下側鍵", mask: .sideDown)
                    mouseMaskToggleItem(index: index, title: "上側鍵", mask: .sideUp)
                } label: {
                    Text(step.mouseButtons.displayString)
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 105)
                }
                .frame(width: 115)

                HStack(spacing: 3) {
                    Text("X:\(step.mouseMoveX)")
                        .font(.system(size: 11, design: .monospaced))
                    Stepper("", value: Binding(
                        get: { Int(step.mouseMoveX) },
                        set: { currentMacroBinding.wrappedValue.steps[index].mouseMoveX = Int8(clamping: $0) }
                    ), in: -127...127, step: 5)
                    .labelsHidden()
                }

                HStack(spacing: 3) {
                    Text("Y:\(step.mouseMoveY)")
                        .font(.system(size: 11, design: .monospaced))
                    Stepper("", value: Binding(
                        get: { Int(step.mouseMoveY) },
                        set: { currentMacroBinding.wrappedValue.steps[index].mouseMoveY = Int8(clamping: $0) }
                    ), in: -127...127, step: 5)
                    .labelsHidden()
                }

                HStack(spacing: 3) {
                    Text("滾輪:\(step.mouseWheel)")
                        .font(.system(size: 11, design: .monospaced))
                    Stepper("", value: Binding(
                        get: { Int(step.mouseWheel) },
                        set: { currentMacroBinding.wrappedValue.steps[index].mouseWheel = Int8(clamping: $0) }
                    ), in: -127...127, step: 1)
                    .labelsHidden()
                }
            } else {
                // 鍵盤巨集步驟編輯器
                Menu {
                    modifierMaskToggleItem(index: index, title: "Ctrl", mask: .leftCtrl)
                    modifierMaskToggleItem(index: index, title: "Shift", mask: .leftShift)
                    modifierMaskToggleItem(index: index, title: "Option (Alt)", mask: .leftAlt)
                    modifierMaskToggleItem(index: index, title: "Command (Win)", mask: .leftGUI)
                } label: {
                    Text(step.modifiers.isEmpty ? "無修飾鍵" : step.modifiers.displayString)
                        .font(.system(size: 11))
                }
                .frame(width: 110)

                Picker("", selection: Binding(
                    get: { step.keyCode },
                    set: { currentMacroBinding.wrappedValue.steps[index].keyCode = $0 }
                )) {
                    ForEach(KeyDefinitions.standardKeys) { k in
                        Text(k.name).tag(k.code)
                    }
                }
                .labelsHidden()
                .frame(width: 110)
            }

            Spacer()

            // 按下時間
            HStack(spacing: 4) {
                Text("按下:")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("\(step.pressDuration * 10)ms")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .frame(width: 48, alignment: .trailing)
                Stepper("", value: Binding(
                    get: { step.pressDuration },
                    set: { currentMacroBinding.wrappedValue.steps[index].pressDuration = $0 }
                ), in: 1...250)
                .labelsHidden()
            }

            // 動作間隔
            HStack(spacing: 4) {
                Text("延遲:")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("\(step.delayAfter * 10)ms")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .frame(width: 48, alignment: .trailing)
                Stepper("", value: Binding(
                    get: { step.delayAfter },
                    set: { currentMacroBinding.wrappedValue.steps[index].delayAfter = $0 }
                ), in: 1...250)
                .labelsHidden()
            }

            // 刪除按鈕
            Button {
                currentMacroBinding.wrappedValue.steps.remove(at: index)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    private func modifierMaskToggleItem(index: Int, title: String, mask: ModifierMask) -> some View {
        let has = currentMacroBinding.wrappedValue.steps[index].modifiers.contains(mask)
        return Button {
            if has {
                currentMacroBinding.wrappedValue.steps[index].modifiers.remove(mask)
            } else {
                currentMacroBinding.wrappedValue.steps[index].modifiers.insert(mask)
            }
        } label: {
            Text(has ? "✓ \(title)" : "   \(title)")
        }
    }

    private func mouseMaskToggleItem(index: Int, title: String, mask: MouseButtonMask) -> some View {
        let has = currentMacroBinding.wrappedValue.steps[index].mouseButtons.contains(mask)
        return Button {
            if has {
                currentMacroBinding.wrappedValue.steps[index].mouseButtons.remove(mask)
            } else {
                currentMacroBinding.wrappedValue.steps[index].mouseButtons.insert(mask)
            }
        } label: {
            Text(has ? "✓ \(title)" : "   \(title)")
        }
    }

    // MARK: - 底部操作列
    private var bottomActionBar: some View {
        HStack {
            Button {
                if currentMacroBinding.wrappedValue.steps.count < maxStepCount {
                    currentMacroBinding.wrappedValue.steps.append(
                        MacroStep(keyCode: 4, mouseButtons: .left, pressDuration: 5, delayAfter: 5)
                    )
                }
            } label: {
                Label("新增動作步驟", systemImage: "plus")
            }
            .disabled(currentMacroBinding.wrappedValue.steps.count >= maxStepCount)

            Button("清空序列") {
                currentMacroBinding.wrappedValue.steps.removeAll()
            }
            .foregroundColor(.secondary)

            Spacer()

            Text("步驟數: \(currentMacroBinding.wrappedValue.steps.count) / \(maxStepCount)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Button {
                let warnings = MacroSafetyAuditor.inspect(macro: currentMacroBinding.wrappedValue)
                if warnings.isEmpty {
                    appVM.saveMacroConfig(for: appVM.selectedKeyIndex)
                } else {
                    safetyWarnings = warnings
                    showSafetyAlert = true
                }
            } label: {
                Label("儲存巨集至設備", systemImage: "arrow.up.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
        }
        .alert("偵測到高風險巨集設定", isPresented: $showSafetyAlert) {
            Button("取消", role: .cancel) {}
            Button("仍要寫入設備", role: .destructive) {
                appVM.saveMacroConfig(for: appVM.selectedKeyIndex)
            }
        } message: {
            Text(safetyWarnings.joined(separator: "\n\n"))
        }
    }
}
