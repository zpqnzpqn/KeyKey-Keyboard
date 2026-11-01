# KeyKey for macOS — User Manual & Installation Guide

This manual provides complete documentation for the KeyKey 2-Key Macro Mechanical Keyboard on macOS, covering hardware connection, software installation, key customization, macro programming, RGB lighting configuration, wireless power-on module pairing, and firmware flashing.

---

## Table of Contents
1. [Hardware Overview & Specifications](#1-hardware-overview--specifications)
2. [System Requirements & Installation](#2-system-requirements--installation)
3. [Quick Start Guide](#3-quick-start-guide)
4. [Features & Functionality](#4-features--functionality)
   - [Key Customization & Modifiers](#41-key-customization--modifiers)
   - [Macro Programming & Live Recording](#42-macro-programming--live-recording)
   - [RGB Lighting Effects & Custom Color](#43-rgb-lighting-effects--custom-color)
   - [Wireless Power-On Module (PowerOnMod)](#44-wireless-power-on-module-poweronmod)
   - [Real-time Keypad Input Tester](#45-real-time-keypad-input-tester)
   - [Profile Backup & Sharing](#46-profile-backup--sharing)
5. [Firmware Update (DFU/IAP) & Safety Notes](#5-firmware-update-dfuiap--safety-notes)
6. [Frequently Asked Questions (FAQ)](#6-frequently-asked-questions-faq)

---

## 1. Hardware Overview & Specifications

KeyKey is a compact 2-key mechanical keypad engineered for rhythm games (such as osu!), professional shortcuts, and high-efficiency productivity workflows.

* **MCU Core**: WCH CH57x 32-bit RISC-V Microcontroller.
* **USB Identification**:
  * **Main Keypad**: Vendor ID `0x5262` (21090) / Product ID `0x4B4B` (19275)
  * **Wireless Power-On Module**: Vendor ID `0x5262` (21090) / Product ID `0x504F` (20559)
  * **DFU Bootloader**: Vendor ID `0x5262` (21090) / Product ID `0x0573` (1395)
* **Protocol**: USB HID Class (Interface 3 with Vendor Output & Input reports).

---

## 2. System Requirements & Installation

### Requirements
* **Operating System**: macOS 13.0 (Ventura), macOS 14.0 (Sonoma), macOS 15.0 (Sequoia), or later.
* **Architecture**: Universal binary supporting both Apple Silicon (M1/M2/M3/M4) and Intel processors.
* **Drivers**: None needed! Native `IOKit.hid` communication is used without requiring third-party kernel extensions or drivers.

### Installation

#### Method 1: Pre-built Binary (Recommended)
1. Download the latest `KeyKey-macOS.dmg` from the GitHub Releases page.
2. Open the DMG image and drag `KeyKey.app` to your `Applications` folder.
3. Launch `KeyKey.app`.

#### Method 2: Build from Source with Xcode
```bash
git clone https://github.com/zpqnzpqn/KeyKey-Keyboard.git
cd KeyKey-Keyboard
open KeyKey.xcodeproj
```
Select the `KeyKey` scheme in Xcode and press `Cmd + R` to build and run.

---

## 3. Quick Start Guide

1. Connect your KeyKey keypad to your Mac using a USB-C data cable.
2. Launch **KeyKey.app**. The status pill at the top right will turn green: "KeyKey Connected".
3. Click on **Key 1** or **Key 2** on the virtual keypad in the main window.
4. Customize the key binding, record a macro, or choose your favorite RGB lighting mode.
5. Click **"Save to Device"**. Configuration is flashed directly into the onboard EEPROM and persists across computers.

---

## 4. Features & Functionality

### 4.1 Key Customization & Modifiers
* **Modifier Keys**: Combine `Ctrl`, `Shift`, `Option (Alt)`, and `Command (Win)`.
* **Standard Keyboard Keys**: Full F1–F12, numeric keys, QWERTY letters, Backspace, Enter, Space, and arrow keys.
* **Consumer Media Controls (16-bit HID Usage)**: Mute, Volume Up/Down, Play/Pause, Track Navigation, Display Brightness, Calculator (`0x0192`), Browser Home (`0x0223`), Menu, and Browser Back (`0x0224`).
* **Mouse Actions (Buttons + Cursor Displacement + Wheel)**: Combine Left, Right, Middle, and Side buttons with **X/Y Cursor Movement (`-127 ~ 127`)** and **Scroll Wheel ticks (`-127 ~ 127`)**.

### 4.2 Macro Programming & Live Recording
* **Dual Macro Types**:
  * **Keyboard Macros**: Up to **14 steps** per key (`[modifiers, keyCode, pressDuration, delayAfter]`).
  * **Mouse Macros**: Up to **8 steps** per key (`[mouseButtons, moveX, moveY, wheel, pressDuration, delayAfter]`).
* **Timing**: Individual Press Duration and Delay After for each step (in 10ms units, `10ms – 2500ms`).
* **Loop Modes**: Infinite loop, Hold-to-loop, or specified count (1–250).
* **Live Keystroke Recording**: Click "Record Keystrokes" and press physical keys on your Mac keyboard (automatically mapped from macOS virtual key codes to USB HID Usage IDs).
* **Macro Safety Auditor**: Automatically warns before flashing macros containing system execution shortcuts (`Cmd+Space`, `Win+R`) or ultra-fast (`<= 20ms`) continuous loops.

### 4.3 RGB Lighting Effects
* **Target Selection**: Apply lighting to **Both Keys Synchronized** (`rgbIndex = 0 & 1` with 60ms pacing), **Key 1 Only**, or **Key 2 Only**.
* **Trigger Mode**: Lights up upon key press (Lucky Color 1, Lucky Color 2, or Custom Color).
* **Nightlight Mode**: Static custom color, Breathing light, or dynamic Rainbow wave.
* **Speed Test (APM)**: Lighting reacts dynamically to your typing speed.
* **Lights Off**: Turns off all onboard LEDs.
* **HSL Color Palette**: Real-time Hue (`0°–359°`), Saturation, and Lightness sliders (automatically scaled to hardware `0–255`).

### 4.4 Wireless Power-On Module (PowerOnMod)
* Connect both KeyKey and PowerOnMod via USB, select which key (**Key 1** or **Key 2**) triggers remote power-on, and click **Pair** to write the keyboard's 6-byte BLE MAC to the module.
* Supports unilateral **Unpair** even when only one of the two devices is connected.

### 4.5 Real-time Keypad Input Tester
* Built-in keystroke test input area with cumulative hit count and timestamped hit history.

### 4.6 Profile Backup, USB/BLE Mode Switch & Factory Safe Reset
* **USB / Bluetooth Mode Switch**: Switch between wired USB priority and wireless BLE mode.
* **Factory Safe Reset**: Overwrites the Write-Only hardware Flash with safe default single keys (`Z` / `X`) and clears any hidden macros.
* **Export & Import Profiles (`.json`)**: Sanitizes all parameter bounds, audits macros for safety, and automatically synchronizes all settings to the connected hardware.

---

## 5. Firmware Update (DFU/IAP) & Official Firmware Links

> [!CAUTION]
> Do not disconnect the USB cable or power off your Mac during firmware update!

### Official Firmware Sources
* **Official Manufacturer Wiki (Robit Wiki)**: [https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE](https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE)
* **Official V1.0.2 Anti-Accidental-Touch Firmware (`KeyKey_V102.bin`)**: [Download ZIP Package](https://pan.lbtrobit.com/f/aQQfR/KeyKey_V102_%E9%98%B2%E8%AF%AF%E8%A7%A6%E7%89%88.zip)

### Flashing Procedure
1. Navigate to the **"Firmware Update"** tab and select the target device (**KeyKey Keypad** or **PowerOnMod**).
2. Click **"Choose Firmware File..."** to select a `.bin` firmware file.
3. The built-in validator verifies file size (`512B – 448KB` for WCH CH573F), checks the RISC-V vector header, and compares the SHA-256 hash against the official allowlist (requiring explicit confirmation for custom unsigned firmware).
4. Click **"Start Firmware Update"** to flash via native `IOKit.usb` Bulk transfer (`0x5262:0x0573`).

---

## 6. Frequently Asked Questions (FAQ)

### Q1: Why does the app say "Keyboard Not Detected"?
* Ensure you are using a USB data cable (some cables only deliver charging current).
* Try another USB-C port or adapter on your Mac.
* Click the "Refresh" button in the top toolbar.

### Q2: Will my settings remain saved when plugged into a PC?
* **Yes!** All settings are written directly to the keypad's internal non-volatile memory. No background driver or software is required on the target machine.

### Q3: How do I change the display language?
* Go to "Settings" in the sidebar and choose between **繁體中文 (台灣)**, **English**, **日本語**, or **Español**.
