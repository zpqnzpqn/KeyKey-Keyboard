# KeyKey 2キー マクロキーボード設定ツール (macOS ネイティブ版)

[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0%2B-blue.svg)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0%20%7C%205.9-orange.svg)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-lightgrey.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Languages](https://img.shields.io/badge/Languages-繁體中文%20%7C%20EN%20%7C%20JA%20%7C%20ES-blueviolet.svg)]()

> **言語の選択 / Other Languages:**  
> [繁體中文](README.md) | [English](README.en.md) | [Español](README.es.md)

**KeyKey 2キー メカニカルキーパッド** のために設計された最新の macOS ネイティブ設定ソフトウェアです。Swift 6、SwiftUI 5、および Apple 純正の `IOKit.hid` フレームワークを採用し、洗練されたフロストガラス調のモダン UI を備えています。追加ドライバは不要で、挿すだけですぐに使用できます。

---

## 🌟 主な機能と特徴

* **モダンな macOS ネイティブフロストガラス UI**: システムのダーク/ライトモードに自動適応する高品位デザイン。
* **インタラクティブな 2キー ビジュアライザー**: 現在のキー割り当てやライティング状態をリアルタイムで立体表示。
* **充実のキーカスタマイズ**: 標準キー、修飾キー（`Ctrl`、`Shift`、`Option`、`Command`）、メディアキー、マウス操作を網羅。
* **高度なマクロシーケンス**: 1キーあたり最大 14 ステップの登録、ミリ秒単位の押下・遅延時間設定、無限/長押し/回数ループ対応。
* **キーストロークのリアルタイム録音**: キーボードを実際に叩くだけで、キーコードとタイミングを自動キャプチャ。
* **ダイナミック RGB ライティング**: トリガー点灯、常夜灯（単色/呼吸/レインボー）、APM 打鍵速度測定、HSL パレット微調整。
* **ワイヤレス電源モジュール管理**: 遠隔 PC 電源操作モジュールとのワンクリックペアリング。
* **リアルタイム入力テスター**: 設定直後にアプリ内で入力動作と打鍵回数を確認できるテストエリア。
* **プロファイルの保存・共有 (JSON)**: すべてのキー設定やライティングを一括でファイルに書き出し/読み込み可能。
* **安全なファームウェア更新 (DFU/IAP)**: 整合性検証機能を搭載し、安全に本体マイコンをアップデート。
* **4か国語完全対応**: 繁体字中国語（台湾標準）、英語、日本語、スペイン語に対応。

---

## 💻 動作環境

* **macOS 13.0 (Ventura) 以降**（macOS 14 Sonoma および macOS 15 Sequoia に完全対応）。
* **対応アーキテクチャ**: Apple Silicon (M1/M2/M3/M4) および Intel プロセッサ両対応。

---

## 🚀 インストール方法

### 推奨：配布版 DMG をダウンロード
[Releases ページ](https://github.com/zpqnzpqn/KeyKey-Keyboard/releases) から最新の `KeyKey-macOS.dmg` をダウンロードし、`KeyKey.app` を「アプリケーション」フォルダへ移動してください。

### ソースコードからビルド
```bash
git clone https://github.com/zpqnzpqn/KeyKey-Keyboard.git
cd KeyKey-Keyboard
open KeyKey.xcodeproj
```
Xcode で `Cmd + R` を押すと、ビルドと起動が実行されます。

---

## 📖 取扱説明書とガイド

* 繁体字中国語: [繁體中文說明書 (docs/manual_zh-TW.md)](docs/manual_zh-TW.md)
* 英語: [User Manual (docs/manual_en.md)](docs/manual_en.md)
* 日本語: [日本語取扱説明書 (docs/manual_ja.md)](docs/manual_ja.md)
* スペイン語: [Manual de Usuario (docs/manual_es.md)](docs/manual_es.md)
* セキュリティ監査および設計ドキュメント:
  * [ハードウェア・プロトコル セキュリティ監査レポート (docs/SECURITY_AUDIT.md)](docs/SECURITY_AUDIT.md)
  * [ドメインモデルおよび通信仕様 (CONTEXT.md)](CONTEXT.md)
  * [ADR-0001: ホスト側セキュリティ緩和策 (docs/adr/0001-host-side-hardware-security-mitigations.md)](docs/adr/0001-host-side-hardware-security-mitigations.md)

---

## 🛠️ プロトコル修正とセキュリティ強化

実機（`KeyKey V1.0.2`）にて検証済みの主な改善点：
* **ベンダー制御 HID フィルタリングと非同期 Interrupt IN**: `PrimaryUsagePage = 1, PrimaryUsage = 0`（64バイト）インターフェースを正確に特定し、ファームウェアバージョン・バッテリー残量・Bluetooth MAC アドレスを非同期で取得。
* **完全なプロトコル互換**: 16ビットメディアキー、マウスXY移動・ホイール操作、キーボードマクロ（最大14ステップ）＆マウスマクロ（最大8ステップ）、両キー同期／個別 RGB 制御、左右キー表示切替、ワイヤレス電源モジュール双方向ペアリング、および `IOKit.usb` Bulk DFU 更新に対応。
* **ホスト側セキュリティ保護機能 (VULN-01〜VULN-05 対策)**:
  * **ワンクリック安全初期化 (Factory Safe Reset)**: Write-Only メモリを安全な初期値（Z/X）で強制上書きし、不正なマクロを消去。
  * **高リスクマクロ検知 (`MacroSafetyAuditor`)**: `Cmd+Space` や 20ms 以下の超高速無限ループを事前警告。
  * **60ms 書き込みスロットリング＆死活監視 (Heartbeat)**: DataFlash 書き込み中のパケットロスを防止。
  * **公式 SHA-256 ホワイトリスト＆バイナリヘッダ検証**: 公式 `KeyKey_V102.bin` のハッシュ検証および不正形式ファイルのブロック。

---

## 🔗 公式ファームウェア・メーカーリンク

* **公式サポート Wiki (Robit Wiki)**: [https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE](https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE)
* **公式 V1.0.2 誤操作防止・消灯版ファームウェア (`KeyKey_V102.bin`)**: [ファームウェアパッケージ (.zip) をダウンロード](https://pan.lbtrobit.com/f/aQQfR/KeyKey_V102_%E9%98%B2%E8%AF%AF%E8%A7%A6%E7%89%88.zip)

---

## 📄 ライセンス

本プロジェクトは [MIT License](LICENSE) のもとで公開されています。
