# KeyKey Domain Model & Hardware Protocol Context

本文檔定義 KeyKey 雙鍵機械小鍵盤與無線遠端開機模組（PowerOnMod）的領域模型（Domain Model）、硬體通訊協定（HID & USB Bulk IAP）與架構邊界，作為程式碼維護與擴充之唯一真實來源（Single Source of Truth）。

---

## 1. 核心領域實體 (Core Domain Entities)

| 領域詞彙 (Ubiquitous Language) | 程式碼對應型別 | 領域定義與不變量 (Invariants) |
| :--- | :--- | :--- |
| **實體設備介面 (Vendor Control Interface)** | [`HIDDevice`](KeyKey/Core/HID/HIDDevice.swift), [`HIDManager`](KeyKey/Core/HID/HIDManager.swift) | KeyKey 複合式 USB 設備會同時列舉多組 HID 介面（標準鍵盤、多媒體、滑鼠與廠商自訂控制通道）。所有配置與狀態查詢必須且僅能透過 `PrimaryUsagePage == 1` 且 `PrimaryUsage == 0`（64-byte Output / Input Report）的廠商控制介面傳輸。 |
| **實體鍵位與視覺方向 (Key Index & Orientation)** | [`KeyConfig`](KeyKey/Models/KeyConfig.swift), `swapKeyOrder` | 硬體韌體內部定義 `keyIndex = 0` 為**按鍵 1（硬體右側鍵）**，`keyIndex = 1` 為**按鍵 2（硬體左側鍵）**。預設 UI 比照原版硬體方向（左 2 右 1），並允許使用者於視覺化介面切換左右顯示順序。 |
| **單鍵配置 (Single Key Assignment)** | [`KeyConfig`](KeyKey/Models/KeyConfig.swift) | `KeyMode.single (1)` 下支援三種硬體輸出型別：<br>1. `keyboard (1)`：8-bit 修飾鍵遮罩 (`ModifierMask`) + 8-bit USB HID Usage ID。<br>2. `consumer (2)`：16-bit Consumer Control Usage ID，拆分為 `packet[6] = lowByte` 與 `packet[7] = highByte`。<br>3. `mouse (3)`：`packet[6] = MouseButtonMask`、`packet[7] = moveX (Int8)`、`packet[8] = moveY (Int8)`、`packet[9] = wheel (Int8)`。 |
| **巨集序列 (Macro Sequence)** | [`MacroConfig`](KeyKey/Models/MacroStep.swift), [`MacroStep`](KeyKey/Models/MacroStep.swift) | `KeyMode.macro (2)` 下分為：<br>1. **鍵盤巨集 (`MACRO_KEYBOARD = 1`)**：最多 **14 步**，自 `packet[7]` 起每步 4 bytes `[modifiers, keyCode, pressDuration, delayAfter]`。<br>2. **滑鼠巨集 (`MACRO_MOUSE = 3`)**：最多 **8 步**，自 `packet[7]` 起每步 6 bytes `[mouseButtons, moveX, moveY, wheel, pressDuration, delayAfter]`。<br>時間單位均為 `10 ms`（數值範圍 `1..250`），循環模式 `loopMode` 為 `1..250`（指定次數）、`254`（按住循環）、`255`（無限循環切換）。 |
| **RGB 燈效配置 (RGB Lighting)** | [`RGBConfig`](KeyKey/Models/RGBConfig.swift), [`RGBTarget`](KeyKey/Models/RGBConfig.swift) | 硬體內建兩顆獨立尋址 LED（`rgbIndex = 0` 對應按鍵 1、`rgbIndex = 1` 對應按鍵 2）。當選擇「雙鍵同步 (`RGBTarget.all`)」時，軟體依序發送 `rgbIndex = 0` 與 `rgbIndex = 1` 兩筆封包。色相 `H` 為 16-bit Big-Endian (`0..359`)，飽和度 `S` 與明度 `L` 在韌體端均為 `0..255`（由 UI 的 `0..100%` 線性映射）。 |
| **無線開機模組配對 (PowerOn Pairing)** | [`KeyKeyCommand`](KeyKey/Core/Protocol/KeyKeyCommand.swift) | 雙向 USB 配對流程：<br>1. 透過 `[0, 3, 6, ...]` 讀取鍵盤之 6-byte 藍牙 MAC。<br>2. 發送 `[0, 3, 7, 1, layer, keyIndex, 0, 0, 0, 0]` 至鍵盤指定開機按鍵。<br>3. 發送 `[0, 3, 7, 2, mac[0..5]]` 至無線開機模組 (`PID = 0x504F`) 完成綁定。<br>解除配對則分別向鍵盤發送 `[0, 3, 7, 1, 255, 255, ...]` 及向模組發送 `[0, 3, 7, 2, 0, 0, 0, 0, 0, 0]`。 |
| **CH57x IAP 韌體升級 (USB Bulk DFU)** | [`CH57xIAP`](KeyKey/Core/DFU/CH57xIAP.swift), [`FirmwareValidator`](KeyKey/Core/DFU/FirmwareValidator.swift) | 發送 `[0, 3, 1, 90, ...]` 後設備重列舉為 WCH CH57x Bootloader (`VID = 0x5262, PID = 0x0573`)，透過 Raw USB Bulk (`EP_OUT = 0x02, EP_IN = 0x82`) 執行：`GET_VER (0x84)` -> `ERASE (0x81)` -> `WRITE (0x80, 62B chunks + end [0x80, 0x00])` -> `VERIFY (0x82, 56B chunks, base offset 0x1000)` -> `END (0x83)`。 |
| **一鍵安全初始化 (Factory Safe Reset)** | [`AppViewModel.factorySafeReset`](KeyKey/ViewModels/AppViewModel.swift) | 針對韌體 Write-Only（無法回讀內部按鍵與巨集配置）之特性，透過強制寫入安全預設單鍵 (`Z` / `X`) 與彩虹燈效覆寫 DataFlash，清除未知來源鍵盤中可能殘留的隱藏巨集。 |
| **高風險巨集檢測 (Macro Safety Audit)** | [`MacroSafetyAuditor`](KeyKey/Core/Profile/ProfileManager.swift) | 於儲存巨集或匯入外部 `.json` 設定檔時，靜態掃描是否包含系統執行快捷鍵 (`Cmd+Space` / `Win+R`) 或總週期 `<= 20ms` 之無限/按住循環，攔截潛在 BadUSB 注入或輸入佇列洪水鎖死。 |
| **寫入節流與存活確認 (Command Pacing & Liveness Heartbeat)** | [`HIDManager`](KeyKey/Core/HID/HIDManager.swift) | 強制連續 HID Output Report 之間保持至少 `60ms` 安全間隔以配合 CH57x DataFlash 抹寫時序，並於配置寫入後 100ms 自動發送 `getVersion` 作為 MCU 存活確認。 |

---

## 2. 關鍵架構決策 (Architectural Decisions)

1. **Report ID 0 剝離與 64-byte 對齊 (`HIDDevice.sendReport`)**：
   - 原版 Python `hidapi` 在 macOS 接收 65-byte 陣列（首 byte 為 `0x00` Report ID）時，底層自動剝離首 byte 並以 64-byte Output Report 呼叫 `IOHIDDeviceSetReport`。原生 Swift `HIDDevice.sendReport` 忠實還原此行為。
2. **非同步 Interrupt IN 事件流 (`IOHIDDeviceRegisterInputReportCallback`)**：
   - 鍵盤韌體針對版本 (`[3, 4, X, Y, Z]`)、電量 (`[3, 5, %]`) 與藍牙 MAC (`[3, 6, m0..m5]`) 皆透過 Interrupt IN 管線非同步回傳，不支援同步 `IOHIDDeviceGetReport`。`HIDDevice` 註冊 Input Report Callback 並透過 Combine `PassthroughSubject` 推送至 `AppViewModel`。

