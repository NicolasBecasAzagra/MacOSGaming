# State of Mac Gaming & Compatibility Layer Research
# Estado del Arte del Gaming en macOS y Capas de Compatibilidad

**Document ID:** `DOC-RES-001`  
**Authors:** Lead Systems Architect & Engineering Team  
**Project:** MacOSGaming (Open Source macOS Gaming Compatibility Ecosystem)  
**Date:** October 2026  
**Revision:** 1.1 (Verification & Accuracy Hardening)  
**Target Hardware:** Apple Silicon (M1, M2, M3, M4 family) & macOS Sonoma (14.x) / Sequoia (15.x) / 16.x  
**Languages:** Bilingual Edition (Español / English)  

---

## Table of Contents / Índice de Contenidos

- [Parte I: Resumen Técnico en Español](#parte-i-resumen-técnico-en-español)
  - [1. Estado Actual del Gaming en macOS y Apple Silicon](#1-estado-actual-del-gaming-en-macos-y-apple-silicon)
  - [2. Comparativa Técnica y Legal de Soluciones](#2-comparativa-técnica-y-legal-de-soluciones)
  - [3. Arquitectura Interna del Stack de Compatibilidad](#3-arquitectura-interna-del-stack-de-compatibilidad)
  - [4. Limitaciones Reales: Anti-Cheats, DRM y Arquitectura](#4-limitaciones-reales-anti-cheats-drm-y-arquitectura)
  - [5. Análisis Profundo de Riot Vanguard y Valorant](#5-análisis-profundo-de-riot-vanguard-y-valorant)
  - [6. Matriz de Compatibilidad Verificada](#6-matriz-de-compatibilidad-verificada)
- [Part II: In-Depth Engineering Research in English](#part-ii-in-depth-engineering-research-in-english)
  - [7. Hardware & Low-Level Substrates: Apple Silicon (M1-M4)](#7-hardware--low-level-substrates-apple-silicon-m1-m4)
  - [8. Instruction & Memory Translation: Rosetta 2, TSO, & AVX2](#8-instruction--memory-translation-rosetta-2-tso--avx2)
  - [9. Graphics Pipeline Translation: Direct3D to Metal](#9-graphics-pipeline-translation-direct3d-to-metal)
  - [10. Operating System Primitives: Wine, Darwin, Audio, Input & I/O](#10-operating-system-primitives-wine-darwin-audio-input--io)
  - [11. Anti-Cheat Enforcement Mechanics & Ring-0 Impossibility](#11-anti-cheat-enforcement-mechanics--ring-0-impossibility)
  - [12. Technical Verification of the Target Game Matrix](#12-technical-verification-of-the-target-game-matrix)
  - [13. Legal, Licensing, and Ethical Boundaries](#13-legal-licensing-and-ethical-boundaries)
  - [14. References & Verified Primary Sources](#14-references--verified-primary-sources)

---

# Parte I: Resumen Técnico en Español

## 1. Estado Actual del Gaming en macOS y Apple Silicon

El ecosistema de videojuegos en macOS se encuentra en su punto de mayor transformación técnica desde la transición de PowerPC a Intel en 2006. El lanzamiento y consolidación de la arquitectura **Apple Silicon** (familias M1, M2, M3 y M4 basadas en microarquitecturas ARM64 personalizadas por Apple) ha dotado a los Mac de una eficiencia de cálculo por vatio destacada, anchos de banda de memoria masivos (hasta >800 GB/s en variantes Ultra/Max) y arquitecturas de memoria unificada (**Unified Memory Architecture - UMA**).

Sin embargo, el gaming en macOS enfrenta una bifurcación estructural:

1. **Capacidades de Hardware:** Las GPUs de Apple Silicon cuentan con aceleración de trazado de rayos por hardware (*Hardware Ray Tracing* en chips M3/M4), sombreado de malla (*Mesh Shading*), compresión de texturas ASTC/BC y *MetalFX Upscaling* (espacial y temporal).
2. **Catálogo Nativo Reducido:** La inmensa mayoría del mercado comercial de videojuegos para PC *(estimación cualitativa sin censo unificado)* se desarrolla y compila contra la plataforma Win32 / DirectX / x86_64, por lo que gran parte de los desarrolladores AAA no publican binarios nativos para macOS.
3. **Punto de Inflexión de Compatibilidad:** La introducción por parte de Apple del **Game Porting Toolkit (GPTK 1 en WWDC23 y GPTK 2 en WWDC24)** demostró la viabilidad técnica de ejecutar binarios de Windows DirectX 11 y 12 sin recompilar sobre macOS mediante capas de traducción en tiempo de ejecución, catalizando proyectos como CrossOver (CodeWeavers), DXMT, MoltenVK y lanzadores como Heroic.

```
+-----------------------------------------------------------------------------------+
|                        APLICACIÓN DE JUEGO (Windows x86_64)                       |
+-----------------------------------------------------------------------------------+
        | (Llamadas Win32 / DirectX)                   | (Instrucciones de CPU x86_64)
        v                                              v
+-------------------------------+             +-------------------------------------+
| Wine / Wine-CX (Espacio Usuario)|             | Rosetta 2 (macOS AOT / JIT Runtime) |
| - Traducción Win32 a POSIX/Darwin            | - Mapeo x86_64 a ARM64              |
| - D3DMetal / DXMT / DXVK      |             | - TSO (Total Store Ordering por HW) |
| - msync (Mach ports / semáforos)             | - Soporte AVX/AVX2 (macOS Sequoia)  |
+-------------------------------+             +-------------------------------------+
        | (Metal Shading Language / APIs)              | (Instrucciones ARM64 ejecutadas)
        v                                              v
+-----------------------------------------------------------------------------------+
|                          KERNEL XNU / METAL 3 / HARDWARE M-SERIES                 |
+-----------------------------------------------------------------------------------+
```

---

## 2. Comparativa Técnica y Legal de Soluciones

| Solución | Tipo Técnico | Rendimiento Observado | Compatibilidad DirectX | Soporte Anti-Cheat | Situación Legal y Licencias |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Apple Game Porting Toolkit (GPTK 1 & 2)** | Capa de evaluación (Wine + D3DMetal + Metal Shader Converter) | Alto *(variable según título y GPU; no existen cifras oficiales de Apple)* | Direct3D 11 & 12 nativo a Metal 3 | Ninguno (Sin Ring-0) | **Restringida:** Licencia de evaluación de Apple. No se permite redistribuir el binario compilado `D3DMetal.framework` en software de consumo. |
| **Wine y Derivados Open Source** (Wine-CX, DXMT, MoltenVK) | Capa de compatibilidad de llamadas al sistema (Syscall translation) | Alto *(optimizado con msync en títulos multihilo)* | D3D9/10/11 (DXMT / DXVK) | Nulo para Ring-0; seguro para Ring-3 | **Totalmente Libre:** Licencias LGPL v2.1+, MIT, Apache 2.0. Legal y redistribuible de forma pública y gratuita. |
| **CrossOver (CodeWeavers)** | Solución comercial sobre Wine con parches propietarios y GPTK integrado | Alto *(integración comercial con soporte activo)* | D3D11, D3D12 (vía D3DMetal con licencia de evaluación / acuerdos) | Ninguno para Ring-0 | **Comercial Propietaria:** Software de pago. CodeWeavers contribuye activamente al código upstream de Wine. |
| **Virtualización (Parallels / Fusion / UTM)** | Máquina Virtual ARM64 Windows 11 con Hypervisor.framework | Medio-Bajo *(sobrecarga por doble capa de emulación e hipervisor)* | D3D11 (emulado); D3D12 muy limitado | Nulo (los anti-cheats detectan y bloquean hipervisores) | **Comercial / Open Source:** Requiere licencia de Windows 11 ARM. Legal, pero ineficiente para juegos de alta demanda. |
| **Cloud Gaming & Streaming** (GeForce NOW, Xbox Cloud, Moonlight) | Renderizado remoto en servidor y streaming de vídeo H.264/HEVC/AV1 | Dependiente de red *(latencia y calidad sujetas a conexión)* | Total (ejecución en Windows nativo del servidor) | Total en el servidor del proveedor | **100% Legal:** Cumple estrictamente los ToS de los distribuidores. Ideal para juegos incompatibles con anti-cheat local. |
| **Porting Nativo (Metal 3)** | Recompilación nativa directa para macOS / ARM64 | Máximo (100% nativo) | Metal 3 puro / MetalFX | Anti-cheats específicos de macOS o servidores dedicados | **100% Legal y Oficial:** Requiere acceso al código fuente del desarrollador original. |

---

## 3. Arquitectura Interna del Stack de Compatibilidad

### 3.1 Traducción de Instrucciones (x86_64 a ARM64)
- **Rosetta 2:** Traduce binarios de 64 bits de Intel a código de máquina ARM64 mediante una combinación de traducción estática AOT (*Ahead-Of-Time*) al instalar/abrir por primera vez y compilación JIT (*Just-In-Time*) para código generado dinámicamente.
- **Hardware TSO (Total Store Ordering):** Las CPUs x86 imponen un modelo estricto de coherencia de memoria. La arquitectura ARM tradicional utiliza un modelo relajado (*weak memory ordering*). Apple diseñó sus núcleos con un registro de control de hardware que activa el modo TSO cuando un hilo corre bajo Rosetta 2, evitando la penalización de sincronización por software de otros emuladores ARM.
- **Instrucciones Vectoriales AVX / AVX2 en macOS Sequoia (macOS 15):**  
  - *Fuente oficial Apple:* En la sesión 10106 de la WWDC24 (*"Evaluate your game for Apple platforms with Game Porting Toolkit 2"*), Apple anunció el soporte de evaluación para instrucciones AVX2 en macOS Sequoia.
  - *Fuente oficial CodeWeavers:* En las notas de versión de CrossOver (versiones 24.0.4+ y 25), CodeWeavers documentó la variable de entorno `ROSETTA_ADVERTISE_AVX=1` para instruir a Rosetta 2 a anunciar la bandera AVX en las respuestas sintéticas de CPUID a aplicaciones de Windows.  
  - *Límite verificado:* Instrucciones AVX-512 no están soportadas. En versiones de macOS anteriores a Sequoia (macOS 14 Sonoma o inferior), las instrucciones AVX desencadenan excepciones `SIGILL`.

### 3.2 Traducción Gráfica (DirectX a Metal)
Existen dos rutas principales en el ecosistema:
1. **Ruta D3DMetal (Apple GPTK):** Traduce Direct3D 12 y 11 directamente a llamadas de la API Metal 3. Traduce shaders HLSL compilados en formato DXIL/DXBC a Metal Shading Language (MSL) en tiempo de ejecución. Ofrece soporte para sombreadores avanzados y trazado de rayos en hardware M3/M4.
2. **Ruta DXMT (DirectX 11 Open Source a Metal):** Desarrollado por la comunidad open source (3Shain), traduce Direct3D 11 directamente a Metal sin pasar por capas intermedias de Vulkan. Es de código abierto (LGPL/MIT), libre de dependencias propietarias de Apple y compatible con *MetalFX Spatial Upscaling*.
3. **Ruta DXVK + MoltenVK:** Traduce DirectX a Vulkan (DXVK), y posteriormente Vulkan a Metal (MoltenVK). Introduce mayor sobrecarga y posibles desajustes por discrepancias entre Vulkan y Metal (descriptores, transform feedback, shaders de geometría).

### 3.3 Audio, Entrada, Red y Sincronización
- **Audio:** Las interfaces de Windows `XAudio2`, `DirectSound` y `WASAPI` son mapeadas por Wine al driver `winecoreaudio.drv`, comunicándose directamente con el subsistema `CoreAudio` de macOS.
- **Input (Mandos y Teclado):** Wine intercepta `DirectInput` y `XInput`, mapeándolos al framework nativo `GameController.framework` (`GCController`) y a `IOHIDManager`. Mandos de Xbox, PlayStation DualSense y Nintendo Switch se reconocen de forma nativa.
- **Sistema de Archivos:** APFS en macOS viene configurado por defecto como *case-insensitive* en volúmenes estándar de sistema, previniendo fallos al cargar recursos de juego con diferencias de mayúsculas/minúsculas.
- **Sincronización de Procesos (msync):** macOS carece de la llamada `futex` de Linux. CodeWeavers implementó **`msync`**, que utiliza puertos y semáforos de Mach del micronúcleo XNU para sincronizar hilos de juego de Windows *(ganancia de rendimiento reportada por CodeWeavers en escenarios de contención multihilo; el impacto varía según el título)*.

---

## 4. Limitaciones Reales: Anti-Cheats, DRM y Arquitectura

### 4.1 La Barrera de los Anti-Cheats de Nivel Kernel (Ring 0)
Los sistemas como **Riot Vanguard**, **Easy Anti-Cheat (EAC)**, **BattlEye** y **Activision Ricochet** instalan controladores de dispositivo de Windows en modo kernel (`.sys`) en el nivel de privilegio más alto de la CPU (**Ring 0**).

1. **Incompatibilidad Fundamental con Wine:** Wine corre estrictamente en espacio de usuario (**Ring 3**) sobre el kernel XNU de macOS. Wine traduce llamadas de API; no emula el kernel NT de Windows. Un driver de kernel `.sys` no puede cargarse ni ejecutarse en macOS porque el kernel XNU rechaza binarios PE/COFF de Windows y carece de las estructuras internas del kernel NT.
2. **Firmas Digitales (WHQL):** Los controladores de anti-cheat deben estar firmados criptográficamente por Microsoft y sus fabricantes.
3. **Módulos de Plataforma Segura (TPM 2.0) y Secure Boot:** Comprueban registros de configuración de plataforma (PCR) en el chip criptográfico físico del equipo.
4. **Detección de Hipervisores:** Anti-cheats como Vanguard comprueban activamente si se están ejecutando bajo un hipervisor (consultando el bit de hipervisor en CPUID y midiendo latencias de instrucciones privilegiadas como `RDTSC` / `VM-Exit`). Si detectan virtualización (Parallels, VMware, UTM), abortan inmediatamente la ejecución.

---

## 5. Análisis Profundo de Riot Vanguard y Valorant

### ¿Por qué Valorant NO PUEDE ejecutarse localmente en Apple Silicon?

| Componente Requerido por Vanguard | Entorno Nativo Windows x86_64 | Entorno Wine / CrossOver / GPTK | Entorno Parallels / VMware / UTM |
| :--- | :--- | :--- | :--- |
| **Driver de Kernel (`vgk.sys`)** | Se carga al arranque en Ring 0 del kernel NT de Windows. | **IMPOSIBLE:** Wine corre en Ring 3 de macOS. El kernel XNU no puede cargar drivers NT. | **INCOMPATIBLE:** Windows 11 en Mac es ARM64; no existe driver ARM64 de Vanguard. |
| **Arquitectura de Procesador** | Binario nativo para arquitecturas Intel/AMD x86_64. | Requiere traducción Rosetta 2 (solo traduce espacio de usuario). | Emulación de emulador Prism de Microsoft (no emula drivers de Ring 0). |
| **Seguridad Basada en Virtualización (VBS/HVCI)** | Obligatoria en Windows 11 para proteger la memoria del kernel. | Inexistente en capas de compatibilidad de espacio de usuario. | No anidable ni certificable sobre Hypervisor.framework de Apple. |
| **TPM 2.0 & UEFI Secure Boot** | Claves criptográficas en silicio validadas por el firmware de la placa base. | No existe capa UEFI ni TPM emulado criptográficamente válido. | El TPM virtual no cuenta con la atestación de hardware de fabricantes PC certificados. |
| **Detección de Máquinas Virtuales** | Ejecución directa en hardware *bare-metal*. | N/A (Wine no es VM, pero falla por falta de driver). | **BLOQUEADO ACTIVAMENTE:** Vanguard detecta el hipervisor y cierra el juego para prevenir trampas por DMA. |

> **Declaración Ética y Técnica:**  
> Cualquier intento de puentear (*bypass*), parchear o interceptar Vanguard no solo viola de forma flagrante los Términos de Servicio de Riot Games (resultando en baneos permanentes de cuenta y hardware), sino que es **técnicamente inviable** sin comprometer la integridad y seguridad del sistema operativo macOS.  
> **Nuestra aplicación mostrará de manera proactiva y transparente:**  
> *"Valorant requiere el anti-cheat a nivel de kernel Riot Vanguard, el cual no es compatible técnica ni legalmente en macOS. Para jugar a Valorant, se requiere un ordenador con Windows físico o utilizar streaming si estuviera soportado."*

### Diferencia Fundamental: League of Legends vs. Valorant
A menudo los usuarios confunden ambos títulos por pertenecer a Riot Games:
- **Valorant:** Solo existe como ejecutable Win32 x86_64 con dependencia obligatoria de Vanguard en Ring 0. **No compatible en macOS.**
- **League of Legends:** Aunque en Windows incorporó Vanguard a partir del parche 14.9 (mayo de 2024), **Riot mantiene un cliente nativo para macOS** (compilado para Mac, que utiliza Metal y se ejecuta a través de Rosetta 2) que **NO requiere Vanguard**, permitiendo a los usuarios de Mac jugar de forma oficial y completamente legal.

---

## 6. Matriz de Compatibilidad Verificada

| Videojuego | Estado de Compatibilidad | Capa Técnica Recomendada | Anti-Cheat Involucrado | Nivel de Confianza | Fecha de Verificación | Dictamen de Ingeniería |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Dota 2** | `Native macOS` | Cliente nativo Steam (MoltenVK -> Metal) | Valve Anti-Cheat (VAC) nativo | **Verificado** | Octubre 2026 | Funciona de forma nativa y oficial en macOS a través de Steam. |
| **League of Legends** | `Native macOS` | Cliente nativo Riot para macOS | Ninguno en Mac (Vanguard solo en Windows) | **Verificado** | Octubre 2026 | Riot mantiene cliente Mac oficial con Metal; no requiere Vanguard en macOS. |
| **Counter-Strike 2 (CS2)** | `Likely compatible via compatibility layer` | CrossOver / GPTK (D3DMetal + msync) | Valve Anti-Cheat (VAC) | **Verificado** *(con matiz VAC)* | Octubre 2026 | Valve confirmó oficialmente que **NO habrá versión para macOS** (Fuentes: Valve Steam Support FAQ, IGN, MacRumors, Oct 2023). Ejecutable en Wine/CrossOver. Desconexiones por verificación de sesión VAC comprobadas; riesgo de baneo permanente por uso de Wine **no verificado oficialmente**. |
| **Elden Ring** | `Likely compatible via compatibility layer` (Offline) / `Requires Windows` (Online) | GPTK / D3DMetal + msync | Easy Anti-Cheat (EAC) | **Verificado** | Octubre 2026 | DX12 corre fluidamente con D3DMetal. EAC no arranca en Wine/macOS, limitando el juego estrictamente al **modo offline monojugador**. |
| **Grand Theft Auto V (GTA V)** | `Likely compatible via compatibility layer` (Historia) / `Not legally/technically supported` (Online) | GPTK 2 / D3DMetal o DXMT | BattlEye (introducido en Septiembre 2024) | **Verificado** | Octubre 2026 | Rockstar integró BattlEye en Septiembre 2024. Modo Historia 100% funcional con `-nobattleye`. GTA Online oficial bloqueado por el driver kernel. |
| **Rocket League** | `Requires Windows` (Online) / `Likely compatible` (Offline local) | Heroic / Wine-CX / DXMT | Easy Anti-Cheat (EAC implementado en abril 2024) | **Verificado** | Octubre 2026 | Psyonix eliminó el soporte nativo Mac en 2020. En abril de 2024 añadieron EAC, impidiendo el multijugador online en Wine. Modos offline/entrenamiento funcionan. |
| **Fortnite** | `Not legally/technically supported` | Cloud Gaming (GeForce NOW / Xbox Cloud) | EAC y BattlEye (Kernel Ring-0) | **Verificado** | Octubre 2026 | La versión nativa quedó congelada en 2020 (Capítulo 2). Incompatible localmente por anti-cheats de kernel. Requiere cloud streaming. |
| **Valorant** | `Not legally/technically supported` | Hardware Windows Físico dedicado | Riot Vanguard (Ring 0, TPM 2.0, Secure Boot) | **Verificado** | Octubre 2026 | **Totalmente incompatible** en macOS / Apple Silicon. Imposible de ejecutar en Wine o máquinas virtuales. |

---

# Part II: In-Depth Engineering Research in English

## 7. Hardware & Low-Level Substrates: Apple Silicon (M1-M4)

The Apple Silicon SoC family represents an integrated System-on-Chip architecture with distinct hardware execution characteristics that directly impact Windows binary emulation:

```
+-----------------------------------------------------------------------------------------+
|                                    APPLE SILICON SoC                                    |
|                                                                                         |
|  +---------------------------+  +--------------------------+  +----------------------+  |
|  | Performance Cores (P)     |  | Efficiency Cores (E)     |  | Apple GPU Complex    |  |
|  | - Firestorm/Avalanche/... |  | - Icestorm/Blizzard/...  |  | - TBDR Architecture  |  |
|  | - TSO Hardware Support    |  | - Energy-efficient tasks |  | - Metal 3 Hardware RT|  |
|  +---------------------------+  +--------------------------+  +----------------------+  |
|                               |                              |                          |
|                               v                              v                          |
|  +-----------------------------------------------------------------------------------+  |
|  |                        UNIFIED MEMORY CONTROLLER & SUBSTRATE                      |  |
|  |             Shared Physical DRAM (Zero-Copy CPU <-> GPU Memory Bus)               |  |
|  +-----------------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------------+
```

### 7.1 Unified Memory Architecture (UMA)
Traditional PC architectures separate CPU system RAM (DDR4/DDR5) and discrete GPU VRAM (GDDR6/HBM) over a PCI Express bus. Game engines running on Windows continuously stage and copy texture, vertex, and index buffers across this bus.

In contrast, Apple Silicon features a **Unified Memory Architecture (UMA)** where CPU cores, GPU clusters, and the Neural Engine share a unified physical LPDDR5/LPDDR5X memory pool:
- High memory bandwidth (up to >800 GB/s on Max and Ultra variants).
- Zero-copy resource access: Textures and vertex buffers resident in CPU virtual memory can be addressed directly by the Metal command queue without bus transfer latency when using `MTLStorageModeShared`.

### 7.2 Tile-Based Deferred Rendering (TBDR) vs. Immediate Mode Rendering (IMR)
Desktop PC GPUs from NVIDIA and AMD are primarily **Immediate Mode Renderers (IMR)**. They process triangles sequentially through the geometry pipeline and rasterize fragments directly to the framebuffer in external VRAM.

Apple GPUs use a **Tile-Based Deferred Renderer (TBDR)**:
1. **Tiling Phase:** The screen is divided into small tiles (typically 16x16 or 32x32 pixels). Primitive geometry is transformed and assigned to tiles in an on-chip tile list.
2. **Hidden Surface Removal (HSR):** Prior to executing expensive fragment/pixel shaders, the GPU determines which geometry is visible at each pixel. Fully occluded fragments are discarded before shading calculations execute.
3. **On-Chip Shading & Blending:** Tile rasterization occurs entirely inside on-chip tile memory. The completed tile is written to main memory once rendering concludes.

---

## 8. Instruction & Memory Translation: Rosetta 2, TSO, & AVX2

### 8.1 Ahead-Of-Time (AOT) and Just-In-Time (JIT) Translation
Rosetta 2 translates x86_64 code to ARM64 instructions:
- Performs an initial AOT translation pass upon application installation, caching translations in `/var/db/oah/`.
- Falls back to JIT compilation for dynamic code execution (`LoadLibrary`, JIT runtimes).

### 8.2 Total Store Ordering (TSO) Hardware Mode
- **x86 Memory Model (TSO):** Reads and writes follow strict ordering guarantees.
- **ARM Memory Model (Weak Ordering):** Loads and stores can be aggressively reordered unless protected by expensive hardware barriers.
- **Apple Silicon Hardware Feature:** Apple CPU cores feature a hardware register mode that enforces x86-compatible TSO when executing translated binaries under Rosetta 2. This avoids the 30% to 50% CPU software barrier penalty seen on standard ARM chips.

### 8.3 Vector Instruction Sets: SSE, AVX, and AVX2 in macOS Sequoia
- **Historical limitation:** Prior to macOS 15, Rosetta 2 only emulated SSE instructions (up to SSE4.2) using ARM NEON registers. Executing 256-bit AVX instructions triggered `EXC_BAD_INSTRUCTION (SIGILL)`.
- **macOS Sequoia 15 Support (Verified):** In WWDC24 Session 10106, Apple officially introduced AVX2 evaluation support in macOS Sequoia.
- **`ROSETTA_ADVERTISE_AVX=1` (Verified):** CodeWeavers documented in CrossOver release notes that setting `ROSETTA_ADVERTISE_AVX=1` causes Rosetta 2 to report AVX support in the synthetic CPUID response, enabling games with pre-flight AVX checks to proceed.
- **Boundaries:** AVX-512 is not supported. Older macOS versions (14 and lower) do not support AVX emulation in Rosetta 2.

---

## 9. Graphics Pipeline Translation: Direct3D to Metal

### 9.1 The Direct3D 12 to Metal 3 Mapping (D3DMetal)
```
+---------------------------------------------------------------------------------+
|                                DIRECT3D 12 PIPELINE                             |
|  - Root Signatures & Descriptor Tables                                          |
|  - HLSL Bytecode (DXBC / DXIL)                                                  |
|  - Command Lists & Command Allocators                                           |
|  - Direct3D 12 Resource Barriers (D3D12_RESOURCE_BARRIER)                       |
+---------------------------------------------------------------------------------+
                                        |
                                        v
                       [ D3DMetal Translation Layer ]
    - JIT converts DXIL/DXBC to Metal Shading Language (MSL 3.0+)
    - Maps D3D12 Descriptor Heaps to Metal Argument Buffers (Tier 2)
    - Replaces explicit D3D12 pipeline fences with MTLSharedEvent & MTLFence
    - Emulates Conservative Rasterization & Mesh Shading
                                        |
                                        v
+---------------------------------------------------------------------------------+
|                                 METAL 3 RUNTIME                                 |
|  - MTLCommandBuffer & MTLComputeCommandEncoder                                  |
|  - Tile-Based Deferred Shading Passes (MTLRenderPassDescriptor)                 |
|  - MetalFX Upscaling Pipeline (MTLFXSpatialScaler / MTLFXTemporalScaler)        |
+---------------------------------------------------------------------------------+
```

### 9.2 Direct3D 11 Translation Options
1. **DXMT (Direct D3D11 to Metal):** Open-source implementation by 3Shain (LGPL/MIT). Translates `ID3D11DeviceContext` directly into Metal 3 command buffers without passing through Vulkan.
2. **D3DMetal (Apple GPTK):** Proprietary Apple evaluation framework for D3D11/D3D12. High performance, but licensed exclusively under Apple Developer evaluation terms.
3. **DXVK + MoltenVK:** Translates D3D11 to Vulkan SPIR-V, then Vulkan to Metal. Introduces shader translation latency and descriptor mapping overhead.

---

## 10. Operating System Primitives: Wine, Darwin, Audio, Input & I/O

- **Synchronization (`msync`):** CodeWeavers implemented Mach-based synchronization primitives (`msync`), eliminating `wineserver` roundtrips.
- **Audio:** `winecoreaudio.drv` routes Windows audio buffers directly to `CoreAudio` with minimal latency.
- **Input:** Windows DirectInput/XInput map to Apple's `GameController.framework` and `IOHIDManager`.
- **Filesystem:** Case-insensitivity in standard APFS prevents Windows path lookup failures.

---

## 11. Anti-Cheat Enforcement Mechanics & Ring-0 Impossibility

### 11.1 The Ring-0 Kernel Architecture
```
+-----------------------------------------------------------------------------------+
|                            USER MODE (RING 3 - Windows)                           |
|  - Game Process (valorant.exe, cs2.exe)                                           |
|  - User-space stub / Watchdog thread                                              |
+-----------------------------------------------------------------------------------+
                                         |
                       [ System Call / IOCTL Boundary ]
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                           KERNEL MODE (RING 0 - Windows NT)                       |
|  - Windows Kernel (ntoskrnl.exe)                                                  |
|  - Anti-Cheat Kernel Driver (vgk.sys, EasyAntiCheat.sys, BEDaisy.sys)             |
|    * ObRegisterCallbacks (Process / Thread access stripping)                     |
|    * PsSetCreateProcessNotifyRoutine (Hook execution monitors)                    |
|    * KeRegisterBugCheckCallback (Integrity verification)                          |
|    * Direct Hardware MSR / CR3 / CR4 inspections                                  |
+-----------------------------------------------------------------------------------+
                                         |
+-----------------------------------------------------------------------------------+
|                        HARDWARE / FIRMWARE SECURITY LAYER                         |
|  - TPM 2.0 (PCR Verification & Remote Attestation)                                |
|  - UEFI Secure Boot (Cryptographic driver signature enforcement)                  |
|  - Hypervisor-Protected Code Integrity (HVCI / VBS)                               |
+-----------------------------------------------------------------------------------+
```

### 11.2 Why Riot Vanguard Cannot Run on macOS
1. **Ring 0 vs. Ring 3:** Vanguard requires `vgk.sys` running at boot in Windows Ring 0. Wine runs purely as a user-mode Darwin task (`mach_task`) on macOS and cannot execute Windows kernel drivers.
2. **SIP & DriverKit:** macOS enforces System Integrity Protection and has deprecated third-party kernel extensions (KEXTs).
3. **Hardware Attestation:** Vanguard verifies TPM 2.0 PCR registers and UEFI Secure Boot keys.
4. **Hypervisor Detection:** Vanguard queries CPUID hypervisor bits (`0x40000000`) and measures VM-exit latency, blocking virtual machines (Parallels, UTM).
5. **No ARM64 Support:** Riot does not provide ARM64 Windows drivers for Vanguard.

---

## 12. Technical Verification of the Target Game Matrix

### 1. Counter-Strike 2 (CS2)
- **Official macOS Status:** Discontinued. Valve officially confirmed in Steam Support FAQ (October 2023) that **Counter-Strike 2 will NOT be released on macOS**, as macOS represented less than 1% of active CS:GO players (reported by IGN and MacRumors).
- **Compatibility Layer Execution:** Playable on Apple Silicon via CrossOver / GPTK with D3DMetal and msync.
- **Anti-Cheat & Matchmaking:** Protected by Valve Anti-Cheat (VAC). Under Wine, users encounter session validation failures (*"VAC was unable to verify your game session"*), interrupting multiplayer matches. **Risk of permanent VAC ban under Wine is officially UNVERIFIED** (Valve does not support Wine, but has not officially stated that running under Wine results in VAC bans).

### 2. Dota 2
- **Official macOS Status:** Native macOS (Verified). Maintained natively by Valve via Steam, utilizing MoltenVK to translate Vulkan to Metal.

### 3. Rocket League
- **Official macOS Status:** Requires Windows for Online Play / Offline Local Playable (Verified). Native macOS support was ended in March 2020. In April 2024, Psyonix added Easy Anti-Cheat (EAC), blocking online multiplayer on Wine/macOS. Offline training and local matches remain functional.

### 4. Elden Ring
- **Official macOS Status:** Likely compatible offline / Requires Windows for online (Verified). D3D12 renders smoothly via D3DMetal. EAC fails on macOS, requiring EAC to be disabled or bypassed to play exclusively in offline single-player mode.

### 5. Grand Theft Auto V (GTA V)
- **Official macOS Status:** Story Mode Compatible / Online Not Supported (Verified). In September 2024, Rockstar added BattlEye anti-cheat to GTA Online. Story Mode is 100% playable by passing `-nobattleye`. GTA Online official servers are inaccessible under Wine.

### 6. Fortnite
- **Official macOS Status:** Not legally/technically supported locally (Verified). Uses EAC and BattlEye. Native Mac build was frozen in 2020 at Chapter 2 Season 3. Must be played via cloud gaming services (GeForce NOW, Xbox Cloud).

### 7. Valorant
- **Official macOS Status:** Not legally/technically supported locally (Verified). Strictly requires Riot Vanguard kernel driver (`vgk.sys`), TPM 2.0, Secure Boot, and bare-metal x86 hardware. Cannot run under Wine or virtual machines.

### 8. League of Legends (LoL)
- **Official macOS Status:** Native macOS (Verified). While Windows received Vanguard in Patch 14.9 (May 2024), Riot officially exempted the native macOS client from Vanguard. Runs natively on macOS via Metal and Rosetta 2.

---

## 13. Legal, Licensing, and Ethical Boundaries

### 13.1 Apple Game Porting Toolkit License Evaluation
Apple distributes the Game Porting Toolkit DMG under the [Game Porting Toolkit Evaluation License Agreement](https://developer.apple.com/games/).

Under Section 2 of this agreement, Apple grants a limited license *"solely for the purpose of developing, testing, or evaluating video games for use on Apple-branded products"*. The license explicitly restricts redistribution, decompilation, and commercial deployment without Apple's separate authorization.

**Policy & Architectural Enforcement in MacOSGaming:**
- **No Redistribution or Recommendation for Play:** MacOSGaming does **NOT** bundle, mirror, or recommend `D3DMetal.framework`, `libd3dshared.dylib`, or any proprietary Apple binaries as an end-user gaming runtime.
- **Open-Source Default:** The default graphics backend for Direct3D 11 in MacOSGaming is **DXMT** (LGPL/MIT) combined with Wine-CX and DXVK-macOS, or alternatively **CodeWeavers CrossOver** under its own commercial license.
- **Advanced Developer Option:** D3DMetal is recognized strictly as an *"opción avanzada bajo tu propia responsabilidad y licencia"*. If an engineer chooses to evaluate D3DMetal, they must independently access [Apple Developer Downloads](https://developer.apple.com/download/all/) using their standard Apple ID (no paid Developer Program enrollment required per Apple Developer Agreement) and accept Apple's license agreement directly. MacOSGaming merely performs local path detection for pre-existing evaluations.

### 13.2 Anti-Cheat & Ethical Guardrails
- **No Bypasses or Cracks:** MacOSGaming strictly prohibits modifying, circumventing, or spoofing anti-cheat systems.
- **Educational Diagnostics:** When an incompatible game is selected, the application clearly explains why kernel-level anti-cheat cannot run on macOS and suggests legal alternatives (e.g. cloud streaming).

---

## 14. References & Verified Primary Sources

1. **Apple Inc.:**
   - WWDC24 Session 10106: *Evaluate your game for Apple platforms with Game Porting Toolkit 2* (Official announcement of AVX2 evaluation support in macOS Sequoia).
   - *Game Porting Toolkit Evaluation License Agreement* (Section 2: Permitted Agreement Uses and Restrictions).
   - Apple Developer Documentation: *About the Rosetta Translation Environment*.
2. **CodeWeavers:**
   - CrossOver Release Notes (CrossOver 24.0.4, 25): *Documentation of `ROSETTA_ADVERTISE_AVX=1` and macOS Sequoia support*.
   - CodeWeavers Engineering Blog: *Msync: Fast synchronization for macOS Wine runtimes*.
3. **Valve Corporation:**
   - Steam Support CS2 FAQ (October 2023): *Counter-Strike 2 Legacy Version and Mac Support Deprecation Notice*.
   - IGN Report (October 2023): *"Counter-Strike 2 Drops Mac Support, Valve Offers Refunds"*.
   - MacRumors Report (October 2023): *"Valve Drops Support for Counter-Strike 2 on Mac"*.
4. **Rockstar Games:**
   - Rockstar Games Customer Support (September 2024): *BattlEye Integration in Grand Theft Auto V and GTA Online PC Update*.
5. **Riot Games:**
   - Riot Games Support Bulletin (May 2024): *Patch 14.9 Notes: Vanguard Rollout on Windows and Mac Exemption Policy*.
6. **Psyonix & Epic Games:**
   - Psyonix Support Update (April 2024): *Rocket League Patch Notes & Easy Anti-Cheat Integration*.
7. **DXMT Project:**
   - 3Shain: *DirectX 11 to Metal translation layer for macOS*, GitHub Repository: `3Shain/dxmt` (LGPL v2.1+ / MIT).
