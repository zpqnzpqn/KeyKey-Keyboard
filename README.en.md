# KeyKey 2-Key Macro Keyboard Configurator (macOS Native)

[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0%2B-blue.svg)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0%20%7C%205.9-orange.svg)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-lightgrey.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Languages](https://img.shields.io/badge/Languages-繁體中文%20%7C%20EN%20%7C%20JA%20%7C%20ES-blueviolet.svg)]()

> **Language Versions:**  
> [繁體中文](README.md) | [日本語](README.ja.md) | [Español](README.es.md)

A modern, native macOS configuration utility built exclusively for the **KeyKey 2-Key Mechanical Keypad**. Completely rewritten with Swift 6, SwiftUI 5, and native Apple `IOKit.hid`, featuring an elegant frosted glass aesthetic, zero third-party drivers, and instant plug-and-play operation.

---

## 🌟 Key Highlights

* **Modern Frosted Glass Aesthetic**: Seamlessly embraces macOS design principles with light and dark mode adaptation.
* **Interactive 2-Key Visualizer**: Tactile keycap simulation with dynamic RGB glow reflecting active mappings and lighting modes.
* **Full Key Customization**: Standard keyboard, modifier combinations (`Ctrl`, `Shift`, `Option`, `Command`), consumer media keys, and mouse actions.
* **Advanced Macro Sequences**: Up to 14 action steps per key, millisecond-accurate duration and delay timing, infinite/hold/count loop modes.
* **Live Keystroke Recording**: Tap keys on your Mac keyboard to automatically capture key codes and intervals.
* **Dynamic RGB Lighting**: Trigger modes (Lucky Colors, Custom), Nightlight (Static, Breathing, Rainbow Wave), Speed Test (APM), and HSL color picker.
* **Wireless Power-On Module**: Easily pair and manage the optional remote computer power-on module.
* **Real-time Input Tester**: Integrated keystroke test field with live hit counter and event logs.
* **Profile Backup & Sharing (JSON)**: Export and import complete keymaps and RGB presets with a single click.
* **Safe Firmware Update (DFU/IAP)**: Built-in binary validation and progress tracking for WCH CH57x MCUs.
* **Quad-Language Localization**: Full native support for Traditional Chinese (Taiwan), English, Japanese, and Spanish.

---

## 💻 System Requirements

* **macOS 13.0 (Ventura) or later** (Fully compatible with macOS 14 Sonoma and macOS 15 Sequoia).
* **Architecture**: Universal binary supporting Apple Silicon (M1–M4) and Intel Macs.

---

## 🚀 Installation

### Option 1: Pre-built Release (Recommended)
Download `KeyKey-macOS.dmg` from the [Releases page](https://github.com/zpqnzpqn/KeyKey-Keyboard/releases), open the disk image, and drag `KeyKey.app` to your `Applications` folder.

### Option 2: Build from Source
```bash
git clone https://github.com/zpqnzpqn/KeyKey-Keyboard.git
cd KeyKey-Keyboard
open KeyKey.xcodeproj
```
Press `Cmd + R` in Xcode to build and run.

---

## 📖 Documentation & Guides

* Traditional Chinese: [繁體中文說明書 (docs/manual_zh-TW.md)](docs/manual_zh-TW.md)
* English: [User Manual (docs/manual_en.md)](docs/manual_en.md)
* Japanese: [日本語取扱説明書 (docs/manual_ja.md)](docs/manual_ja.md)
* Spanish: [Manual de Usuario (docs/manual_es.md)](docs/manual_es.md)
* Architecture & Security Audit:
  * [Hardware & Protocol Security Audit Report (docs/SECURITY_AUDIT.md)](docs/SECURITY_AUDIT.md)
  * [Domain Model & Protocol Specification (CONTEXT.md)](CONTEXT.md)
  * [ADR-0001: Host-Side Hardware Security Mitigations (docs/adr/0001-host-side-hardware-security-mitigations.md)](docs/adr/0001-host-side-hardware-security-mitigations.md)

---

## 🛠️ Protocol Fixes & Security Enhancements

Verified against physical `KeyKey V1.0.2` hardware:
* **Vendor Control HID Filtering & Async Interrupt IN**: Matches `PrimaryUsagePage = 1, PrimaryUsage = 0` (64-byte reports) and receives real-time firmware version, battery percentage, and BLE MAC telemetry via `IOHIDDeviceRegisterInputReportCallback`.
* **Complete Protocol Alignment**: Supports 16-bit Consumer Media keys, single-key mouse buttons + X/Y cursor displacement + scroll wheel, 14-step keyboard macros & 8-step mouse macros, dual-key synchronized or per-key RGB (`0..255` HSL scaling), key orientation toggle, two-device PowerOnMod pairing, and native `IOKit.usb` Bulk IAP flashing.
* **Host-Side Security Mitigations (VULN-01 to VULN-05)**:
  * **Factory Safe Reset**: One-click overwrite of Write-Only hardware Flash to clear potential hidden macros.
  * **Macro Safety Auditor**: Detects high-risk shortcuts (`Cmd+Space`, `Win+R`) and ultra-fast (`<= 20ms`) infinite loops.
  * **60ms Command Pacing & Liveness Heartbeat**: Prevents CH57x DataFlash write race conditions and packet drops.
  * **Firmware SHA-256 Allowlist & Binary Header Inspection**: Validates WCH CH573F (`448 KB` max) binaries and requires explicit confirmation for unsigned custom firmware.

---

## 🔗 Official Firmware & Manufacturer Links

* **Official Robit Wiki (KeyKey BLE)**: [https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE](https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE)
* **Official V1.0.2 Anti-Accidental-Touch Firmware (`KeyKey_V102.bin`)**: [Download Firmware Package (.zip)](https://pan.lbtrobit.com/f/aQQfR/KeyKey_V102_%E9%98%B2%E8%AF%AF%E8%A7%A6%E7%89%88.zip)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
