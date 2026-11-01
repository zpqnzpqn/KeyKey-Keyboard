# KeyKey 雙鍵巨集鍵盤設定程式 (macOS 原生版)

[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0%2B-blue.svg)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0%20%7C%205.9-orange.svg)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-lightgrey.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Languages](https://img.shields.io/badge/Languages-繁體中文%20%7C%20EN%20%7C%20JA%20%7C%20ES-blueviolet.svg)]()

> **其他語言版本 / Other Languages / 他の言語 / Otros Idiomas:**  
> [English](README.en.md) | [日本語](README.ja.md) | [Español](README.es.md)

專為 **KeyKey 雙鍵小鍵盤** 量身打造的 macOS 現代化原生設定軟體。採用 Swift 6、SwiftUI 5 與 Apple 原生 IOKit.hid 框架重構，具備細緻的磨砂玻璃質感視覺效果，無須安裝第三方驅動程式，隨插即用。

---

## 🌟 主要特色

* **現代 macOS 原生磨砂玻璃介面**：完美融入 macOS 系統設計語彙，支援深色與淺色外觀自適應。
* **擬真雙鍵視覺化鍵盤**：立體鍵帽與動態光效，即時展示當前指派按鍵與燈光狀態。
* **完整按鍵自訂**：支援標準鍵盤鍵位、修飾鍵組合 (`Ctrl`、`Shift`、`Option`、`Command`)、多媒體消費鍵與滑鼠動作。
* **進階巨集編程**：單鍵最多支援 14 個動作步驟，支援毫秒級時間微調、無限循環、按住循環與次數循環。
* **即時按鍵錄製 (Live Recording)**：無須手動輸入數字，直接在 Mac 鍵盤上敲擊即可自動捕捉鍵碼與時間差。
* **動態 RGB 燈效調色盤**：按下亮燈 (幸運色/自訂)、小夜燈 (恆亮/呼吸/彩虹)、手速測驗 (APM) 與 HSL 精準調光。
* **無線開機模組 (PowerOnMod)**：支援遠端無線電腦開機接收模組之配對與管理。
* **鍵位即時測試區**：內建擊鍵測試框與打擊次數計數板，設定完立即在 App 內驗證。
* **設定檔匯出/匯入 (JSON)**：一鍵備份所有鍵位與燈光配置，方便多組設定檔切換。
* **安全韌體升級 (DFU/IAP)**：內建 CH57x 二進位檔案防護校驗，安全穩定更新設備韌體。
* **四國語言完整支援**：內建繁體中文（台灣標準資訊用語）、English、日本語與 Español。

---

## 💻 系統需求

* **macOS 13.0 (Ventura) 或更高版本**（相容 macOS 14 Sonoma 與 macOS 15 Sequoia）。
* **硬體架構**：原生支援 Apple Silicon (M1/M2/M3/M4) 及 Intel 處理器。

---

## 🚀 下載與安裝

### 方式一：下載發行版 (推薦)
前往 [Releases 頁面](https://github.com/zpqnzpqn/KeyKey-Keyboard/releases) 下載最新版的 `KeyKey-macOS.dmg`，開啟後將 `KeyKey.app` 拖曳至「應用程式」資料夾即可使用。

### 方式二：從原始碼自行建構
```bash
# 複製儲存庫
git clone https://github.com/zpqnzpqn/KeyKey-Keyboard.git
cd KeyKey-Keyboard

# 使用 Xcode 開啟專案
open KeyKey.xcodeproj
```
於 Xcode 內點擊 `Cmd + R` 即自動編譯並啟動應用程式。

亦可使用 Swift Package Manager 編譯：
```bash
swift build -c release
```

---

## 📖 使用說明與文件

詳細的圖文操作教學、巨集設定範例、RGB 調光、韌體升級與硬體資安評估報告，請參閱：
* 繁體中文：[完整使用說明書 (docs/manual_zh-TW.md)](docs/manual_zh-TW.md)
* English: [User Manual (docs/manual_en.md)](docs/manual_en.md)
* 日本語: [取扱説明書 (docs/manual_ja.md)](docs/manual_ja.md)
* Español: [Manual de Usuario (docs/manual_es.md)](docs/manual_es.md)
* 資安與領域文件：
  * [硬體與通訊協定資安弱點評估報告 (docs/SECURITY_AUDIT.md)](docs/SECURITY_AUDIT.md)
  * [領域模型與硬體協定規範 (CONTEXT.md)](CONTEXT.md)
  * [ADR-0001：主機端針對 CH57x 硬體弱點之防禦緩解架構 (docs/adr/0001-host-side-hardware-security-mitigations.md)](docs/adr/0001-host-side-hardware-security-mitigations.md)

---

## 🛠️ 硬體協定修正與資安強化重點

本原生重構版本經由實機 (`KeyKey V1.0.2`) 驗證，完整修正並強化了以下硬體通訊與安全防護機制：

1. **精準鎖定 Vendor HID 控制通道與非同步 Interrupt IN**：
   * 過濾複合式 USB 設備的 4 組 HID 介面，僅連接 `PrimaryUsagePage = 1, PrimaryUsage = 0` 之 64-byte 控制通道。
   * 自動剝離首 byte `0x00` Report ID 對齊 64-byte Output Report，並透過 `IOHIDDeviceRegisterInputReportCallback` 非同步接收韌體版本 (`V1.0.2`)、電池電量 (`%`) 與藍牙 MAC 位址。
2. **完整硬體協定對齊**：
   * **單鍵與多媒體**：補齊 16-bit Consumer 多媒體鍵（計算機 `0x0192`、瀏覽器首頁 `0x0223`、返回 `0x0224`）高低位元組拆分，以及單鍵滑鼠按鍵組合 + X/Y 游標位移 + 滾輪刻度。
   * **雙模巨集編程**：支援「鍵盤巨集（最多 14 步，每步 4 bytes）」與「滑鼠巨集（最多 8 步，每步 6 bytes）」，並將即時錄製之 macOS Virtual KeyCode 自動轉換為 USB HID Usage ID。
   * **RGB 雙鍵同步與獨立尋址**：支援「雙鍵同步 (`rgbIndex = 0 & 1`)」與單鍵獨立燈效切換，並將飽和度 `S` / 明度 `L` 線性映射為硬體 `0..255` 規格。
   * **開機模組雙向配對 & 真實 CH57x USB Bulk DFU**：完整支援鍵盤與無線開機模組 (`0x504F`) 雙向配對及 WCH CH573F (`0x0573`) Raw USB Bulk 韌體燒錄。
3. **主機端資安防護機制 (VULN-01 ~ VULN-05 緩解)**：
   * **一鍵安全初始化 (`Factory Safe Reset`)**：針對韌體 Write-Only（不支援回讀內部巨集）特性，可一鍵將雙鍵強制覆寫回安全預設單鍵 (`Z` / `X`)，清除未知來源鍵盤可能殘留之隱藏巨集。
   * **高風險巨集靜態檢測 (`MacroSafetyAuditor`)**：自動偵測 `Cmd+Space`、`Win+R` 等系統快捷鍵或週期 `<= 20ms` 之高速無限循環巨集並跳出風險警告。
   * **60ms 命令寫入節流與 Heartbeat 存活確認**：防止連續寫入 CH57x DataFlash 時發生靜默掉包。
   * **韌體標頭檢查與 SHA-256 白名單 (`FirmwareValidator`)**：內建官方 `KeyKey_V102.bin` SHA-256 白名單並攔截 ELF/ZIP/空白映像，刷入自訂韌體須二次確認。

---

## 🔗 原廠資源與韌體取得管道

* **原廠說明書與韌體發佈主頁（蘿蔔兔 Robit Wiki）**：[https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE](https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE)
* **官方 V1.0.2 防誤觸關燈版韌體下載 (`KeyKey_V102.bin`)**：[點此下載 ZIP 韌體包](https://pan.lbtrobit.com/f/aQQfR/KeyKey_V102_%E9%98%B2%E8%AF%AF%E8%A7%A6%E7%89%88.zip)
  * *註：出廠預設即為 `V1.0.2`。官方「防誤觸關燈版」功能與出廠版相同，僅移除「同時長按雙鍵 3 秒切換燈效」之硬體快捷鍵，適合不希望長按誤觸亮燈的使用者。*

---

## 🔌 硬體通訊規格

* **主鍵盤**：USB VID `0x5262` (21090) / PID `0x4B4B` (19275) / Vendor Control Interface (`UsagePage=1, Usage=0`)
* **無線開機模組**：USB VID `0x5262` (21090) / PID `0x504F` (20559) / Vendor Control Interface (`UsagePage=1, Usage=0`)
* **DFU 模式**：USB VID `0x5262` (21090) / PID `0x0573` (1395) / USB Bulk (`EP_OUT=0x02, EP_IN=0x82`)
* **通訊管道**：Apple 原生 `IOKit.hid` 與 `IOKit.usb`（零驅動、免輔助延伸功能）

---

## 📄 開源授權

本專案採用 [MIT License](LICENSE) 授權釋出。
