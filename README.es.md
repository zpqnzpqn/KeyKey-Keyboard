# Configurador de Teclado Macro de 2 Teclas KeyKey (Nativo para macOS)

[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0%2B-blue.svg)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0%20%7C%205.9-orange.svg)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-lightgrey.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Languages](https://img.shields.io/badge/Languages-繁體中文%20%7C%20EN%20%7C%20JA%20%7C%20ES-blueviolet.svg)]()

> **Otros Idiomas / Other Languages:**  
> [繁體中文](README.md) | [English](README.en.md) | [日本語](README.ja.md)

Una utilidad de configuración nativa y moderna para macOS diseñada exclusivamente para el **Teclado Mecánico de 2 Teclas KeyKey**. Completamente reescrita con Swift 6, SwiftUI 5 y `IOKit.hid` nativo de Apple, con una elegante estética de vidrio esmerilado, sin necesidad de controladores adicionales y funcionamiento plug-and-play inmediato.

---

## 🌟 Características Principales

* **Estética de Vidrio Esmerilado Nativa**: Se integra perfectamente con el diseño de macOS, con compatibilidad para modo claro y oscuro.
* **Visualizador Interactivo de 2 Teclas**: Simulación táctil de teclas con resplandor RGB dinámico que refleja las asignaciones activas.
* **Personalización Total de Teclas**: Teclado estándar, combinaciones con modificadores (`Ctrl`, `Shift`, `Option`, `Command`), teclas multimedia y acciones de ratón.
* **Secuencias de Macros Avanzadas**: Hasta 14 pasos de acción por tecla, ajustes de tiempo en milisegundos, bucle infinito, al mantener o por contador.
* **Grabación de Teclas en Vivo**: Pulse teclas en su Mac para registrar códigos y tiempos de manera automática.
* **Iluminación Dinámica RGB**: Modos al pulsar (Colores de la suerte, Personalizado), Luz nocturna (Fija, Respiración, Arcoíris), Prueba de velocidad (APM) y paleta HSL.
* **Módulo de Encendido Inalámbrico**: Empareje y controle fácilmente el receptor de encendido remoto para su computadora.
* **Probador de Entrada en Tiempo Real**: Área de prueba integrada con contador de pulsaciones y registro de eventos.
* **Copia de Seguridad de Perfiles (JSON)**: Exporte e importe configuraciones completas de teclas e iluminación con un solo clic.
* **Actualización Segura de Firmware (DFU/IAP)**: Verificación integrada de integridad para microcontroladores WCH CH57x.
* **Soporte Cuatrilingüe Completo**: Traducido al Chino Tradicional (Taiwán), Inglés, Japonés y Español.

---

## 💻 Requisitos del Sistema

* **macOS 13.0 (Ventura) o superior** (Totalmente compatible con macOS 14 Sonoma y macOS 15 Sequoia).
* **Arquitectura**: Binario universal compatible con Apple Silicon (M1–M4) y procesadores Intel.

---

## 🚀 Instalación

### Opción 1: Archivo DMG precompilado (Recomendado)
Descargue `KeyKey-macOS.dmg` desde la [página de Releases](https://github.com/zpqnzpqn/KeyKey-Keyboard/releases), abra la imagen de disco y arrastre `KeyKey.app` a su carpeta `Aplicaciones`.

### Opción 2: Compilar desde el código fuente
```bash
git clone https://github.com/zpqnzpqn/KeyKey-Keyboard.git
cd KeyKey-Keyboard
open KeyKey.xcodeproj
```
Pulse `Cmd + R` en Xcode para compilar e iniciar la aplicación.

---

## 📖 Documentación y Manuales

* Chino Tradicional: [繁體中文說明書 (docs/manual_zh-TW.md)](docs/manual_zh-TW.md)
* Inglés: [User Manual (docs/manual_en.md)](docs/manual_en.md)
* Japonés: [日本語取扱説明書 (docs/manual_ja.md)](docs/manual_ja.md)
* Español: [Manual de Usuario (docs/manual_es.md)](docs/manual_es.md)
* Auditoría de Seguridad y Arquitectura:
  * [Informe de Auditoría de Seguridad de Hardware y Protocolo (docs/SECURITY_AUDIT.md)](docs/SECURITY_AUDIT.md)
  * [Modelo de Dominio y Especificación del Protocolo (CONTEXT.md)](CONTEXT.md)
  * [ADR-0001: Mitigaciones de Seguridad en el Host (docs/adr/0001-host-side-hardware-security-mitigations.md)](docs/adr/0001-host-side-hardware-security-mitigations.md)

---

## 🛠️ Correcciones de Protocolo y Mejoras de Seguridad

Verificado en hardware real (`KeyKey V1.0.2`):
* **Filtrado HID de Control y Recepción Asíncrona Interrupt IN**: Conecta exclusivamente con la interfaz de control de 64 bytes (`PrimaryUsagePage = 1, PrimaryUsage = 0`) y lee versión de firmware, nivel de batería y dirección MAC Bluetooth en tiempo real.
* **Compatibilidad Total con el Protocolo**: Teclas multimedia de 16 bits, desplazamiento X/Y y rueda de ratón, macros de teclado (14 pasos) y ratón (8 pasos), iluminación RGB sincronizada o individual por tecla, inversión visual de teclas, emparejamiento bidireccional con PowerOnMod y actualización DFU USB Bulk nativa.
* **Protecciones de Seguridad (Mitigación de VULN-01 a VULN-05)**:
  * **Restablecimiento Seguro de Fábrica (Factory Safe Reset)**: Sobrescribe la memoria Flash Write-Only con valores seguros (`Z` / `X`).
  * **Auditor de Seguridad de Macros (`MacroSafetyAuditor`)**: Advierte sobre combinaciones críticas (`Cmd+Space`, `Win+R`) o bucles infinitos ultrarrápidos (`<= 20ms`).
  * **Control de Flujo de 60ms y Heartbeat**: Evita pérdidas de paquetes durante la escritura en DataFlash.
  * **Lista Blanca SHA-256 y Validación de Binarios**: Verifica el firmware oficial `KeyKey_V102.bin` (límite de 448 KB para CH573F).

---

## 🔗 Firmware Oficial y Enlaces del Fabricante

* **Wiki Oficial del Fabricante (Robit Wiki)**: [https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE](https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE)
* **Firmware Oficial V1.0.2 Anti-Toque Accidental (`KeyKey_V102.bin`)**: [Descargar paquete de firmware (.zip)](https://pan.lbtrobit.com/f/aQQfR/KeyKey_V102_%E9%98%B2%E8%AF%AF%E8%A7%A6%E7%89%88.zip)

---

## 📄 Licencia

Este proyecto está bajo la [Licencia MIT](LICENSE).
