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
* **Control Multimedia**: Volumen, Silencio, Reproducir/Pausa, Brillo, Calculadora, Navegador.
* **Acciones del Ratón**: Clic izquierdo, derecho, central y botones laterales.

### 4.2 Programación de Macros y Grabación en Vivo
* **Capacidad**: Hasta **14 pasos de acción** por tecla.
* **Tiempos**: Duración de pulsación y retardo configurables en unidades de 10 ms.
* **Modos de Bucle**: Bucle infinito, Bucle al mantener o Contador de repeticiones (1-250).
* **Grabación en Vivo**: Haga clic en "Grabar pulsaciones" y presione las teclas en su teclado para capturarlas automáticamente.

### 4.3 Efectos de Luz RGB
* **Modo Toque**: Se ilumina al pulsar (Color de la suerte 1 o 2, o Color personalizado).
* **Luz Nocturna**: Color estático, Modo respiración u Onda arcoíris.
* **Prueba de Velocidad (APM)**: La luz reacciona según la velocidad de tecleo.
* **Apagar Luces**: Desactiva todos los LEDs.
* **Paleta HSL**: Deslizadores precisos de Tono, Saturación y Brillo.

### 4.4 Módulo de Encendido Inalámbrico (PowerOnMod)
* Empareje y desvincule su teclado con el módulo de encendido remoto de la computadora con un solo clic.

### 4.5 Probador de Teclas en Tiempo Real
* Campo de prueba integrado para verificar la respuesta del teclado y contador de pulsaciones.

### 4.6 Copia de Seguridad y Perfiles
* Exporte e importe perfiles completos en formato `.json` a través de "Configuración".

---

## 5. Actualización de Firmware (DFU/IAP) y Seguridad

> [!CAUTION]
> ¡No desconecte el cable USB ni apague el Mac durante la actualización del firmware!

1. Vaya a la pestaña **"Actualizar firmware"**.
2. Haga clic en **"Seleccionar archivo de firmware..."** y elija el archivo `.bin` oficial.
3. El verificador integrado comprobará el tamaño (512B - 64KB) y la suma de comprobación SHA-256.
4. Haga clic en **"Comenzar actualización de firmware"** para flashear de forma segura.

---

## 6. Preguntas Frecuentes (FAQ)

### P1: ¿Por qué la aplicación muestra "Teclado no detectado"?
* Compruebe que está utilizando un cable con soporte de datos (no solo de carga).
* Pruebe en otro puerto USB del Mac y pulse el botón de actualizar en la esquina superior.

### P2: ¿Se conservan los ajustes al conectar el teclado a una PC con Windows?
* **¡Sí!** La configuración se escribe directamente en el chip del teclado y funciona en cualquier sistema sin necesidad de software adicional.

### P3: ¿Cómo cambio el idioma de la interfaz?
* En la barra lateral, acceda a "Configuración" > "Idioma de la interfaz" y elija entre **繁體中文 (台灣)**, **English**, **日本語** o **Español**.
