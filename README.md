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

詳細的圖文操作教學、巨集設定範例、RGB 調光與韌體升級指引，請參閱：
* 繁體中文：[完整使用說明書 (docs/manual_zh-TW.md)](docs/manual_zh-TW.md)
* English: [User Manual (docs/manual_en.md)](docs/manual_en.md)
* 日本語: [取扱説明書 (docs/manual_ja.md)](docs/manual_ja.md)
* Español: [Manual de Usuario (docs/manual_es.md)](docs/manual_es.md)

---

## 🔌 硬體通訊規格

* **主鍵盤**：USB VID `0x5262` (21090) / PID `0x4B4B` (19275) / Interface 3
* **無線開機模組**：USB VID `0x5262` (21090) / PID `0x504F` (20559) / Interface 3
* **DFU 模式**：USB VID `0x5262` (21090) / PID `0x0573` (1395)
* **通訊管道**：Apple 原生 `IOKit.hid`（零驅動、免輔助延伸功能、免輪詢）

---

## 📄 開源授權

本專案採用 [MIT License](LICENSE) 授權釋出。
