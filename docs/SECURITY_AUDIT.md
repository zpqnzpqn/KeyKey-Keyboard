# KeyKey 硬體與通訊協定資安弱點評估報告 (Hardware & Protocol Security Audit Report)

- **評估日期**：2026-11-01
- **受測硬體**：KeyKey 雙鍵機械鍵盤 (`VID: 0x5262 / 21090`, `PID: 0x4B4B / 19275`, 實機韌體 `V1.0.2`, BLE MAC `XX:XX:XX:XX:XX:XX（已去識別化）`)
- **關聯週邊**：無線遠端開機模組 PowerOnMod (`VID: 0x5262`, `PID: 0x504F`)、WCH CH57x IAP Bootloader (`VID: 0x5262`, `PID: 0x0573`)
- **評估方法**：原版韌體通訊協定逆向分析、USB HID 描述符與介面權限檢測、實機封包交換驗證、領域模型邊界分析

---

## 1. 執行摘要 (Executive Summary)

KeyKey 採用沁恆微電子（WCH）**CH57x 系列 RISC-V BLE/USB MCU**。硬體透過 USB 複合設備（Composite Device）暴露 4 組 HID 介面，其中第 4 組（`UsagePage = 0x0001, Usage = 0x0000`）為 64-byte 廠商控制通道。

經實機檢測與協定分析，由於硬體設計定位於輕量消費級客製化小鍵盤，**韌體層缺乏密碼學簽章、雙向身分驗證、配對金鑰交換與封包完整性校驗**。本報告共識別出 **5 項硬體與協定弱點（1 項高危、2 項中高危、2 項中低危）**，並區分「硬體韌體固有限制」與「可於 macOS 軟體端（KeyKey.app）主動防禦緩解」之具體方案。

| 編號 | 弱點名稱 | 風險等級 | 層級 | 軟體端可否緩解 |
| :--- | :--- | :---: | :--- | :--- |
| **VULN-01** | 無認證觸發 DFU 模式與無簽章韌體燒錄 (CH57x IAP) | **High (高)** | 韌體 / Bootloader | 部分可緩解（SHA-256 白名單 / 簽章清單檢查） |
| **VULN-02** | 免權限 HID 控制通道之持久化巨集注入與盲寫入 (Write-Only) | **High (高)** | USB HID 協定 | 可緩解（高風險巨集攔截、一鍵安全初始化） |
| **VULN-03** | 無線開機模組 (PowerOnMod) 明文 MAC 綁定與 BLE 仿冒風險 | **Medium-High (中高)** | BLE / 配對協定 | 需硬體改版（軟體端可加註警示與快速解綁） |
| **VULN-04** | 控制封包無 ACK/CRC 校驗與連續寫入 Flash 掉包風險 | **Medium (中)** | USB HID 協定 | **完全可緩解**（命令佇列節流 + Heartbeat 驗證） |
| **VULN-05** | 韌體指令參數缺乏邊界保護與設定檔匯入越界風險 | **Low-Medium (中低)** | 軟體 / 協定邊界 | **完全可緩解**（領域不變量強制清洗與 Clamping） |

---

## 2. 弱點詳細分析 (Detailed Findings)

### VULN-01：無認證觸發 DFU 模式與無簽章韌體燒錄 (Unauthenticated DFU Entry & Unsigned Firmware)
- **嚴重度**：**High (高)**
- **技術細節**：
  1. 在 [`KeyKeyCommand.swift`](../KeyKey/Core/Protocol/KeyKeyCommand.swift) 中，指令 `enterIAP = [0, 3, 1, 90, 0, 0, 0, 0, 0]` 可由主機端直接送往廠商 HID 介面，**不需要使用者在鍵盤上按住任何實體按鍵（無 Physical User Presence 驗證）**，鍵盤即立刻切斷 HID 並重啟進入 WCH CH57x USB Bootloader (`0x5262:0x0573`)。
  2. 在 [`CH57xIAP.swift`](../KeyKey/Core/DFU/CH57xIAP.swift) 對應之 Bootloader 協定中，`ERASE (0x81)`、`WRITE (0x80)`、`VERIFY (0x82)` 完全以明文 USB Bulk (`EP_OUT=0x02`) 傳輸，晶片端無 Secure Boot 或數位簽章檢查。
- **潛在風險場景**：
  - 本機任何一般權限（非 root）背景程序皆可發送 `enterIAP` 並刷入竄改後的惡意韌體（BadUSB 持久化），或發送 `ERASE` 導致設備變磚（Denial of Service）。
- **防禦與緩解建議**：
  - **軟體端 (`KeyKey.app`)**：於 [`FirmwareValidator.swift`](../KeyKey/Core/DFU/FirmwareValidator.swift) 加入「官方已知韌體 SHA-256 雜湊白名單」驗證機制；若使用者選取未知雜湊的 `.bin` 檔，預設阻止燒錄並要求勾選「強制刷入未簽章自訂韌體」二次確認。

---

### VULN-02：免權限 HID 控制通道之持久化巨集注入與無狀態回讀 (Unauthenticated Persistent Macro Write & Blind State)
- **嚴重度**：**High (高)**
- **技術細節**：
  1. macOS 的 `IOHIDManager` 對於 `PrimaryUsagePage == 0x01 (Generic Desktop)` 且 `PrimaryUsage == 0x07 (Keyboard)` 的標準鍵盤介面會受「輸入監控 (Input Monitoring)」TCC 權限保護；但 KeyKey 的第 4 組控制介面宣告為 **`PrimaryUsagePage == 0x01, PrimaryUsage == 0x00 (Undefined)`**。
  2. 因此，macOS 將該控制介面視為一般非鍵盤外設，**任何無特殊權限的沙盒外程序皆可開啟並呼叫 `IOHIDDeviceSetReport` 寫入單鍵或 14 步鍵盤巨集**。
  3. 此外，韌體協定為 **Write-Only（僅能寫入、無法讀取目前鍵盤內的按鍵與巨集配置）**，僅支援查詢版本 (`[3,4]`)、電量 (`[3,5]`) 與 MAC (`[3,6]`)。主機端軟體無法在連線時讀取並審查鍵盤內部是否已被植入惡意巨集（如 `Cmd + Space` 開啟 Spotlight 並輸入終端指令，或設定 `loopMode = 255` 無限循環造成輸入阻斷）。
- **防禦與緩解建議**：
  - **軟體端 (`KeyKey.app`)**：
    1. **高風險巨集與設定檔靜態掃描**：在匯入 `.json` 設定檔或儲存巨集前，檢查是否包含高風險組合鍵（如 `Cmd+Space`、`Win+R`）或極端高速無限循環（`loopMode == .infinite` 且 `pressDuration + delayAfter <= 2` 即 20ms 內），主動提示使用者風險。
    2. **新增「一鍵安全重設 (Factory Safe Reset)」**：在 UI 提供一鍵覆寫功能，將 `keyIndex = 0` 與 `keyIndex = 1` 強制寫回單純無害按鍵（如 `Z` 與 `X`）並重置燈效，消除未知來源鍵盤中可能殘留的隱藏巨集。

---

### VULN-03：無線遠端開機模組 (PowerOnMod) 明文 MAC 綁定與 BLE 仿冒風險 (Plaintext MAC Pairing)
- **嚴重度**：**Medium-High (中高)**
- **技術細節**：
  - 根據實機協定，配對無線開機模組時：
    1. 主機先以 `[0, 3, 6, ...]` 從鍵盤讀出 6-byte 明文 BLE MAC（如 `XX:XX:XX:XX:XX:XX`）。
    2. 主機發送 `[0, 3, 7, 1, layer, keyIndex, ...]` 給鍵盤指定開機鍵。
    3. 主機發送 `[0, 3, 7, 2, mac[0..5]]` 將鍵盤的 6-byte MAC 直接寫入開機模組。
  - 整個配對流程**未生成或交換任何隨機對稱金鑰（No AES-CCM / No Challenge-Response / No Rolling Code）**，完全依賴 6-byte 藍牙 MAC 位址作為信任憑證。
- **潛在風險場景**：
  - 由於 BLE 廣播封包在空氣中以明文傳遞發送端 MAC 位址，鄰近無線電範圍內的攻擊者可嗅探到鍵盤 MAC 後，使用任何支援修改 BD_ADDR 的藍牙開發板偽造相同 MAC 發送封包，進而觸發開機模組短路主機板 Power SW（導致未授權開機或強制斷電關機）。
- **防禦與緩解建議**：
  - **硬體限制說明**：此為現有 `V1.0.2` 韌體協定之設計限制，無法僅靠主機端 App 改變無線封包加密方式。
  - **軟體端 (`KeyKey.app`)**：於 [`PowerOnModuleView.swift`](../KeyKey/Views/PowerOn/PowerOnModuleView.swift) 介面加入安全提示（建議勿於公開或高安全需求環境依賴無線開機模組作為唯一存取控制），並保留支援單獨插上鍵盤或單獨插上模組時皆可強制執行「解除配對 (`powerOnUnpair`)」。

---

### VULN-04：控制封包無 ACK/CRC 校驗與連續寫入 Flash 掉包風險 (Lack of Framing Integrity & Flash Write Race Condition)
- **嚴重度**：**Medium (中)**
- **技術細節**：
  1. 64-byte HID Output Report 無 Sequence Number，亦無 CRC 校驗碼；且 `cmdKey (1)`、`cmdRGB (2)` 寫入後，韌體**不會回傳任何 ACK Input Report**。
  2. 當主機端連續發送多筆指令（例如：`RGBTarget.all` 連續發送 `rgbIndex = 0` 與 `rgbIndex = 1` 兩筆封包，或匯入設定檔時一次寫入雙鍵與雙燈），CH57x MCU 在處理第一筆封包並抹寫內部 DataFlash 的數十毫秒期間，可能無法處理緊接著抵達的第二筆 USB Interrupt/Control Report，然而 macOS `IOHIDDeviceSetReport` 仍回傳成功，造成**軟硬體狀態不一致（Silent Drop）**。
- **防禦與緩解建議**：
  - **軟體端 (`KeyKey.app`)**：
    1. 於 [`HIDManager.swift`](../KeyKey/Core/HID/HIDManager.swift) 建立**序列化寫入佇列與節流保護（Command Pacing，每筆配置寫入強制間隔 60ms）**。
    2. 每次寫入配置後，自動排程一次輕量級查詢（如 `getVersion`）以確認 MCU 已完成 Flash 寫入並正常回應。

---

### VULN-05：韌體指令參數缺乏邊界保護與設定檔匯入越界風險 (Parameter Out-of-Bounds & Profile Deserialization)
- **嚴重度**：**Low-Medium (中低)**
- **技術細節**：
  1. 在 [`KeyKeyCommand.swift`](../KeyKey/Core/Protocol/KeyKeyCommand.swift) 中，韌體對部分欄位假設主機端永遠傳入合法範圍：
     - `keyIndex` 僅能為 `0` 或 `1`（若傳入 `>= 2`，韌體內部陣列索引可能越界寫入其他 EEPROM/DataFlash 位址）。
     - `layer` 僅能為 `0`。
     - 巨集 `pressDuration` 與 `delayAfter` 在原版軟體限制為 `1..250`（若傳入 `0` 或 `254/255`，可能與特殊標記衝突）。
  2. 在 [`ProfileManager.swift`](../KeyKey/Core/Profile/ProfileManager.swift) 匯入外部 JSON 設定檔時，原本直接透過 `JSONDecoder` 載入，若使用者匯入遭手工修改的惡意 `.json`（例如 `keyIndex: 99`、`pressDuration: 0`、超過 14 步的巨集陣列），直接儲存至設備可能導致韌體行為異常。
- **防禦與緩解建議**：
  - **軟體端 (`KeyKey.app`)**：於 `KeyKeyCommand` 封包建構層與 `ProfileManager.importProfile` 反序列化層強制執行嚴格邊界清洗（Clamping：`keyIndex` 限制 `0...1`、`layer` 限制 `0`、`pressDuration/delayAfter` 限制 `1...250`、`hue` 限制 `0...359`、`saturation/lightness` 限制 `0...100`）。

