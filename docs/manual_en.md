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
* **Consumer Media Controls**: Mute, Volume Up/Down, Play/Pause, Track Navigation, Display Brightness, Calculator, Browser Home/Back.
* **Mouse Actions**: Left, Right, Middle click, and Forward/Backward side buttons.

### 4.2 Macro Programming & Live Recording
* **Capacity**: Up to **14 action steps** per key.
* **Timing**: Individual Press Duration and Delay After for each step (in 10ms units).
* **Loop Modes**: Infinite loop, Hold-to-loop, or specified count (1–250).
* **Live Keystroke Recording**: Click "Record Keystrokes" and press physical keys on your Mac keyboard to automatically capture key codes and intervals.

### 4.3 RGB Lighting Effects
* **Trigger Mode**: Lights up upon key press (Lucky Color 1, Lucky Color 2, or Custom Color).
* **Nightlight Mode**: Static custom color, Breathing light, or dynamic Rainbow wave.
* **Speed Test (APM)**: Lighting reacts dynamically to your typing speed.
* **Lights Off**: Turns off all onboard LEDs.
* **HSL Color Palette**: Real-time Hue, Saturation, and Brightness sliders with visual preview.

### 4.4 Wireless Power-On Module (PowerOnMod)
* Pair your KeyKey keyboard with the wireless computer power-on receiver.
* Check module connection status and firmware version.
* One-click pairing and unpairing.

### 4.5 Real-time Keypad Input Tester
* Built-in keystroke test input area.
* Displays cumulative hit count and timestamped hit history.

### 4.6 Profile Backup & Sharing
* Export your entire keymap, macros, and RGB presets to a single `.json` file.
* Import shared profiles anytime via "Settings" > "Profile Management".

---

## 5. Firmware Update (DFU/IAP) & Safety Notes

> [!CAUTION]
> Do not disconnect the USB cable or power off your Mac during firmware update!

1. Navigate to the **"Firmware Update"** tab.
2. Click **"Choose Firmware File..."** to select an official `.bin` firmware file.
3. The built-in validator verifies file size (512B – 64KB) and computes the SHA-256 checksum.
4. Click **"Start Firmware Update"** and confirm. The app automatically guides the device through DFU reboot, Flash erase, block write, and verification.

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
