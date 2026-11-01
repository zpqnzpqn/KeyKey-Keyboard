import SwiftUI

/// 巨集序列編輯器與即時錄製介面
public struct MacroEditorView: View {
    @ObservedObject var appVM: AppViewModel
    @State private var loopSelection: Int = 0 // 0: 無限, 1: 按住循環, 2: 指定次數
    @State private var loopCountValue: Int = 10

    public init(appVM: AppViewModel) {
        self.appVM = appVM
    }

    private var currentMacroBinding: Binding<MacroConfig> {
        appVM.selectedKeyIndex == 0 ? $appVM.key1Macro : $appVM.key2Macro
    }

    public var body: some View {
        VStack(spacing: 16) {
            // 頂部控制列：目標鍵位與即時錄製
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
    }

    // MARK: - 頂部控制列
    private var topControlBar: some View {
        HStack {
            Text("編輯目標：按鍵 \(appVM.selectedKeyIndex + 1)")
                .font(.system(size: 15, weight: .bold))

            Spacer()

            // 即時按鍵錄製開關
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

        return HStack(spacing: 14) {
            // 序號
            Text("#\(index + 1)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 28)

            // 按鍵標籤
            Text(step.displayLabel)
                .font(.system(size: 14, weight: .semibold))
                .frame(minWidth: 100, alignment: .leading)

            Spacer()

            // 按下時間
            HStack(spacing: 4) {
                Text("按下:")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("\(step.pressDuration * 10) ms")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
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
                Text("\(step.delayAfter * 10) ms")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
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
            .padding(.leading, 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - 底部操作列
    private var bottomActionBar: some View {
        HStack {
            Button {
                if currentMacroBinding.wrappedValue.steps.count < 14 {
                    currentMacroBinding.wrappedValue.steps.append(
                        MacroStep(keyCode: 4, pressDuration: 5, delayAfter: 5)
                    )
                }
            } label: {
                Label("新增動作步驟", systemImage: "plus")
            }
            .disabled(currentMacroBinding.wrappedValue.steps.count >= 14)

            Button("清空序列") {
                currentMacroBinding.wrappedValue.steps.removeAll()
            }
            .foregroundColor(.secondary)

            Spacer()

            Text("步驟數: \(currentMacroBinding.wrappedValue.steps.count) / 14")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Button {
                appVM.saveMacroConfig(for: appVM.selectedKeyIndex)
            } label: {
                Label("儲存巨集至設備", systemImage: "arrow.up.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
