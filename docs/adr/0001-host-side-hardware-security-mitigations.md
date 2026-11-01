# ADR 0001: 主機端針對 CH57x 硬體與協定弱點之防禦緩解架構

- **狀態 (Status)**：已採納 (Accepted)
- **日期 (Date)**：2026-11-01
- **關聯報告**：[`docs/SECURITY_AUDIT.md`](../SECURITY_AUDIT.md)

## 背景與問題 (Context and Problem Statement)

KeyKey 雙鍵鍵盤與無線開機模組採用 WCH CH57x MCU，其出廠韌體 (`V1.0.2`) 與 USB HID / IAP Bootloader 協定存在五項固有限制（詳見 `docs/SECURITY_AUDIT.md`）：
1. **VULN-01**：IAP Bootloader 無韌體數位簽章驗證，誤刷非 CH57x 裸機二進位檔或損壞映像將導致設備變磚或持久性植入。
2. **VULN-02**：按鍵與巨集配置為 **Write-Only**（無讀取指令），且控制通道 (`UsagePage=1, Usage=0`) 無須特權即可寫入，使用者無法得知鍵盤內部是否殘留惡意巨集或極端高速無限循環。
3. **VULN-03**：無線開機模組僅以 6-byte 明文 BLE MAC 綁定，無滾動碼或對稱金鑰。
4. **VULN-04**：寫入配置無 ACK 回應，連續高速寫入會因 MCU 忙於寫入內部 DataFlash 而靜默丟包。
5. **VULN-05**：韌體未對 `keyIndex`、`layer`、`pressDuration` 做嚴格邊界檢查。

在不修改出廠硬體韌體的前提下，主機端 `KeyKey.app` 必須承擔安全守門員角色。

## 決策 (Decision)

我們在 `KeyKey.app` 實作四道主機端防禦層：

1. **一鍵安全初始化 (`factorySafeReset`) 與高風險巨集靜態審查 (`MacroSafetyAuditor`)**：
   - 於偏好設定提供「一鍵安全初始化」，強制以已知安全的單鍵 (`Z` / `X`) 覆寫硬體 Flash 雙鍵槽位。
   - 於巨集儲存及設定檔匯入時，靜態檢查是否含 `Cmd/Win + Space`、`Cmd/Win + R` 或總週期 `<= 20ms` 之連續循環，觸發二次確認警告。
2. **韌體二進位結構檢查與未簽章韌體二次確認鎖 (`FirmwareValidator`)**：
   - 攔截 ELF、ZIP、Mach-O、Intel HEX 與全 `0x00`/`0xFF` 無效映像。
   - 比對官方 SHA-256 白名單；未列於白名單之自訂韌體預設鎖定更新按鈕，須明確勾選風險確認方可燒錄。
3. **60ms 命令佇列節流與寫入後 Heartbeat (`HIDManager`)**：
   - 於 `HIDManager` 強制每次 `sendReport` 間隔至少 `60ms`，並在配置寫入 (`cmdType == 1` 或 `2`) 後 100ms 自動發送 `getVersion` 驗證 MCU 存活。
4. **領域不變量強制清洗 (`KeyKeyProfile.sanitized` & `KeyKeyCommand`)**：
   - 匯入外部 `.json` 設定檔與封包序列化時，強制將 `layer` 限制為 `0`、`keyIndex` 限制為 `0...1`、`pressDuration/delayAfter` 限制為 `1...250`，並在匯入通過審查後自動同步寫入硬體。

## 影響與取捨 (Consequences)

- **優點**：消除連續寫入掉包問題、防止誤刷非裸機 `.bin` 變磚、避免 `10ms` 無限巨集鎖死系統輸入，並提供清除未知鍵盤隱藏巨集的可靠手段。
- **取捨**：多筆封包同步（如匯入完整設定檔或安全初始化共 4 筆封包）需耗時約 `180ms ~ 240ms` 的節流等待時間，但對使用者體感影響極小。

