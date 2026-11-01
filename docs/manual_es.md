# KeyKey para macOS — Manual de Usuario e Instalación

Este manual proporciona la documentación completa para el teclado mecánico de 2 teclas KeyKey en macOS, incluyendo la conexión de hardware, instalación de software, personalización de teclas, programación de macros, configuración de luz RGB, emparejamiento del módulo de encendido inalámbrico y actualización de firmware.

---

## Índice
1. [Descripción del Hardware y Especificaciones](#1-descripción-del-hardware-y-especificaciones)
2. [Requisitos del Sistema e Instalación](#2-requisitos-del-sistema-e-instalación)
3. [Guía de Inicio Rápido](#3-guía-de-inicio-rápido)
4. [Funcionalidades Detalladas](#4-funcionalidades-detalladas)
   - [Asignación de Teclas y Modificadores](#41-asignación-de-teclas-y-modificadores)
   - [Programación de Macros y Grabación en Vivo](#42-programación-de-macros-y-grabación-en-vivo)
   - [Efectos de Luz RGB y Colores Personalizados](#43-efectos-de-luz-rgb-y-colores-personalizados)
   - [Módulo de Encendido Inalámbrico (PowerOnMod)](#44-módulo-de-encendido-inalámbrico-poweronmod)
   - [Probador de Teclas en Tiempo Real](#45-probador-de-teclas-en-tiempo-real)
   - [Copia de Seguridad y Compartir Perfiles](#46-copia-de-seguridad-y-compartir-perfiles)
5. [Actualización de Firmware (DFU/IAP) y Seguridad](#5-actualización-de-firmware-dfuiap-y-seguridad)
6. [Preguntas Frecuentes (FAQ)](#6-preguntas-frecuentes-faq)

---

## 1. Descripción del Hardware y Especificaciones

KeyKey es un teclado mecánico compacto de 2 teclas diseñado para juegos de ritmo (como osu!), atajos rápidos y flujos de trabajo de alta productividad.

* **Núcleo MCU**: Microcontrolador RISC-V de 32 bits serie WCH CH57x.
* **Identificadores USB**:
  * **Teclado Principal**: Vendor ID `0x5262` (21090) / Product ID `0x4B4B` (19275)
  * **Módulo de Encendido Inalámbrico**: Vendor ID `0x5262` (21090) / Product ID `0x504F` (20559)
  * **Modo DFU Bootloader**: Vendor ID `0x5262` (21090) / Product ID `0x0573` (1395)
* **Protocolo**: Clase estándar USB HID (Interfaz 3 con informes de Entrada/Salida).

---

## 2. Requisitos del Sistema e Instalación

### Requisitos
* **Sistema Operativo**: macOS 13.0 (Ventura), macOS 14.0 (Sonoma), macOS 15.0 (Sequoia) o superior.
* **Compatibilidad**: Binario universal compatible con Apple Silicon (M1/M2/M3/M4) y procesadores Intel.
* **Controladores**: ¡Ninguno necesario! Utiliza el framework nativo `IOKit.hid` de Apple.

### Métodos de Instalación

#### Método 1: Archivo DMG precompilado (Recomendado)
1. Descargue la última versión de `KeyKey-macOS.dmg` desde la sección de Releases en GitHub.
2. Abra el archivo DMG y arrastre `KeyKey.app` a su carpeta de `Aplicaciones`.
3. Inicie `KeyKey.app`.

#### Método 2: Compilación desde el código fuente con Xcode
```bash
git clone https://github.com/zpqnzpqn/KeyKey-Keyboard.git
cd KeyKey-Keyboard
open KeyKey.xcodeproj
```
Seleccione el esquema `KeyKey` en Xcode y pulse `Cmd + R` para compilar y ejecutar.

---

## 3. Guía de Inicio Rápido

1. Conecte su teclado KeyKey al Mac mediante un cable de datos USB Tipo C.
2. Inicie **KeyKey.app**. La etiqueta de estado superior cambiará a verde: "KeyKey Conectado".
3. Haga clic en la **Tecla 1** o **Tecla 2** en el teclado virtual interactivo.
4. Asigne la tecla deseada, programe una macro o configure la luz RGB.
5. Haga clic en **"Guardar en el dispositivo"**. Los ajustes se guardan en la memoria integrada del teclado.

---

## 4. Funcionalidades Detalladas

### 4.1 Asignación de Teclas y Modificadores
* **Modificadores**: Combine `Ctrl`, `Shift`, `Option (Alt)` y `Command (Win)`.
* **Teclado Estándar**: Teclas F1 a F12, números, letras QWERTY, Espacio, Enter, etc.
* **Control Multimedia (16 bits)**: Volumen, Silencio, Reproducir/Pausa, Brillo, Calculadora (`0x0192`), Inicio del navegador (`0x0223`) y Atrás (`0x0224`).
* **Acciones del Ratón**: Combinación de botones con **desplazamiento de cursor X/Y (`-127 ~ 127`)** y **rueda de desplazamiento (`-127 ~ 127`)**.

### 4.2 Programación de Macros y Grabación en Vivo
* **Capacidad Dual**: **Macros de teclado (hasta 14 pasos)** y **Macros de ratón (hasta 8 pasos)**.
* **Tiempos**: Duración de pulsación y retardo configurables en unidades de 10 ms (`10ms – 2500ms`).
* **Modos de Bucle**: Bucle infinito, Bucle al mantener o Contador de repeticiones (1-250).
* **Auditor de Seguridad**: Advierte antes de guardar macros con atajos del sistema (`Cmd+Space`, `Win+R`) o bucles infinitos ultrarrápidos (`<= 20ms`).

### 4.3 Efectos de Luz RGB
* **Selección de Destino**: Aplique efectos a **Ambas Teclas Sincronizadas**, **Solo Tecla 1** o **Solo Tecla 2**.
* **Paleta HSL**: Deslizadores precisos de Tono (`0°–359°`), Saturación y Brillo (escalados a `0–255` en hardware).

### 4.4 Módulo de Encendido Inalámbrico (PowerOnMod)
* Seleccione qué tecla (**Tecla 1** o **Tecla 2**) activará el encendido remoto y vincule la dirección MAC Bluetooth del teclado con el módulo. Admite desvinculación unilateral.

### 4.5 Probador de Teclas en Tiempo Real
* Campo de prueba integrado para verificar la respuesta del teclado y contador de pulsaciones.

### 4.6 Perfiles, Cambio USB/BLE y Restablecimiento Seguro de Fábrica
* **Restablecimiento Seguro de Fábrica (Factory Safe Reset)**: Sobrescribe la memoria Flash Write-Only con teclas simples seguras (`Z` / `X`) para eliminar posibles macros ocultas.
* **Exportar e Importar Perfiles (`.json`)**: Valida los límites de parámetros y sincroniza automáticamente toda la configuración con el hardware conectado.

---

## 5. Actualización de Firmware (DFU/IAP) y Enlaces Oficiales

> [!CAUTION]
> ¡No desconecte el cable USB ni apague el Mac durante la actualización del firmware!

* **Wiki Oficial del Fabricante (Robit Wiki)**: [https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE](https://wiki.lbtrobit.com/zh/HID/KeyKeyBLE)
* **Firmware Oficial V1.0.2 Anti-Toque Accidental (`KeyKey_V102.bin`)**: [Descargar paquete ZIP](https://pan.lbtrobit.com/f/aQQfR/KeyKey_V102_%E9%98%B2%E8%AF%AF%E8%A7%A6%E7%89%88.zip)

1. Vaya a la pestaña **"Actualizar firmware"** y seleccione el dispositivo de destino (**Teclado KeyKey** o **PowerOnMod**).
2. Elija el archivo `.bin`. El verificador comprobará el tamaño (`512B - 448KB` para CH573F), el encabezado RISC-V y la lista blanca SHA-256.
3. Haga clic en **"Comenzar actualización de firmware"** para flashear mediante USB Bulk nativo (`0x5262:0x0573`).

---

## 6. Preguntas Frecuentes (FAQ)

### P1: ¿Por qué la aplicación muestra "Teclado no detectado"?
* Compruebe que está utilizando un cable con soporte de datos (no solo de carga).
* Pruebe en otro puerto USB del Mac y pulse el botón de actualizar en la esquina superior.

### P2: ¿Se conservan los ajustes al conectar el teclado a una PC con Windows?
* **¡Sí!** La configuración se escribe directamente en el chip del teclado y funciona en cualquier sistema sin necesidad de software adicional.

### P3: ¿Cómo cambio el idioma de la interfaz?
* En la barra lateral, acceda a "Configuración" > "Idioma de la interfaz" y elija entre **繁體中文 (台灣)**, **English**, **日本語** o **Español**.
