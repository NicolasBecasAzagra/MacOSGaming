# Technical Architecture Specification
# Arquitectura Técnica del Sistema — MachPlay Bridge

**Document ID:** `DOC-ARCH-001`  
**Project:** MachPlay Bridge (macOS Open Source Gaming Compatibility Ecosystem)  
**Status:** Proposed Architecture / En Revisión Técnica  
**Date:** October 2026  
**Lead Architect:** Engineering Team  

---

## 1. Executive Vision & Design Philosophy

**MachPlay Bridge** is an enterprise-grade, open-source macOS desktop application and modular engine designed to configure, launch, monitor, and diagnose Windows games on Apple Silicon (M1/M2/M3/M4) computers running macOS Sonoma (14.x) and macOS Sequoia (15.x/16.x).

### Core Principles
1. **Zero-Compromise Legal & Ethical Posture:** Strictly zero bundling or distribution of proprietary game binaries, cracked DLLs, or bypasses. Respect anti-cheat boundaries and terms of service.
2. **Native macOS Excellence:** Built with Swift 6 and SwiftUI, adhering to Apple Human Interface Guidelines (HIG). Fast startup (<200ms), zero Electron bloat, low memory footprint (<80MB idle), dark-mode native, and integrated with macOS Game Mode.
3. **Pluggable Architecture:** Decoupled engine allowing interchangeable graphics translators (DXMT, DXVK, D3DMetal via local user-provided runtime), prefix runtimes, and game launchers.
4. **Diagnostic-First Engineering:** Automated log inspection, proactive hardware suitability assessment, and intelligent error triage so users never stare at an unexplained crash.

---

## 2. Monorepo Organization

```
MacOSGaming/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                 # Lint, Typecheck, Unit Tests on macOS runner
│   │   ├── release.yml            # Semantic release, notarization, DMG bundle
│   │   └── security.yml           # Dependency auditing & SAST scan
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── compatibility_request.md
│   └── PULL_REQUEST_TEMPLATE.md
├── apps/
│   └── MachPlay/                  # Native macOS SwiftUI App
│       ├── App/
│       │   ├── MachPlayApp.swift  # App lifecycle & NavigationSplitView
│       │   └── MenuCommands.swift # Menu bar shortcuts & system actions
│       ├── Views/
│       │   ├── Dashboard/         # System specs, chip telemetry, readiness
│       │   ├── Library/           # Installed games & launcher integration
│       │   ├── GameDetail/        # Game profile settings, graphics toggles
│       │   ├── Diagnostics/       # Live logs, log analysis, diagnostic export
│       │   └── Settings/          # Prefix management & runtime selector
│       └── Resources/             # Assets, Icons, Localizations (en, es)
├── packages/
│   ├── MachPlayCore/              # Swift Engine Package
│   │   ├── Sources/MachPlayCore/
│   │   │   ├── SystemDetector/    # Chip (M1-M4), RAM, GPU, OS, Rosetta status
│   │   │   ├── Compatibility/     # Game Profiles DB, Anti-Cheat Sentinel
│   │   │   ├── PrefixManager/     # Wine/Darwin prefix creation & isolation
│   │   │   ├── Runner/            # Subprocess runner, environment injector
│   │   │   ├── Diagnostics/       # Real-time log parser & pattern classifier
│   │   │   └── Launchers/         # Steam, Epic, GOG local scanner
│   │   └── Tests/MachPlayCoreTests/
│   └── MachPlayCLI/               # Headless CLI for developers & automation
│       └── Sources/MachPlayCLI/   # 'machplay doctor', 'machplay run', etc.
├── docs/
│   ├── research/
│   │   └── state-of-mac-gaming.md # Low-level engineering research
│   ├── architecture.md            # This specification
│   ├── roadmap.md                 # Phased engineering roadmap
│   └── contributing.md            # Contributor guidelines & code style
├── LICENSE                        # Open-source license (MIT)
└── README.md                      # Comprehensive project documentation
```

---

## 3. High-Level System Architecture

```
+-----------------------------------------------------------------------------------+
|                           PRESENTATION LAYER (SwiftUI 6)                          |
|  - System Health Dashboard      - Unified Game Library     - Game Detail & Config |
|  - Real-Time Diagnostic Console - Setup & Guided Onboarding - Alert & Sentinel UI   |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                              CORE ENGINE (MachPlayCore)                           |
|                                                                                   |
|  +--------------------+  +----------------------+  +---------------------------+  |
|  | SystemDetector     |  | AntiCheatSentinel    |  | GameProfileRepository     |  |
|  | - M-Series Specs   |  | - Rule Engine        |  | - JSON Game Profiles      |  |
|  | - Rosetta 2 Status |  | - Safe Mode Blocks   |  | - Per-Game Overrides      |  |
|  +--------------------+  +----------------------+  +---------------------------+  |
|                                                                                   |
|  +--------------------+  +----------------------+  +---------------------------+  |
|  | PrefixManager      |  | ProcessRunner        |  | DiagnosticClassifier      |  |
|  | - Sandbox Isolation|  | - Environment Flags  |  | - Crash Pattern Matcher   |  |
|  | - Config Injection |  | - Stdout/Stderr Pipe |  | - Solution Generator      |  |
|  +--------------------+  +----------------------+  +---------------------------+  |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                        COMPATIBILITY SUBSTRATES (Darwin / Wine)                   |
|  - Rosetta 2 Binary Translator (with ROSETTA_ADVERTISE_AVX=1 on Sequoia)          |
|  - Wine-CX / Wine Darwin user-space runtime (with Mach-based msync)               |
|  - Graphics Translators: DXMT (Direct D3D11->Metal) / D3DMetal (Apple Evaluation) |
|  - Audio: winecoreaudio.drv -> macOS CoreAudio                                    |
|  - Input: GCController / IOHIDManager -> XInput                                   |
+-----------------------------------------------------------------------------------+
```

---

## 4. Subsystem Detailed Design

### 4.1 System Detection Engine (`SystemDetector`)
Queries macOS kernel APIs and IOKit without spawning expensive shell processes:
- **Processor Identification:** Calls `sysctlbyname("machdep.cpu.brand_string", ...)` and queries `hw.optional.arm64`. Identifies exact generation: M1, M2, M3, M4 (Base, Pro, Max, Ultra).
- **GPU & Unified Memory:** Employs `MTLCopyAllDevices()` to query default Metal device, max buffer size, ray tracing hardware tier, and unified memory size.
- **Rosetta 2 Verification:** Checks existence and accessibility of `/Library/Apple/usr/libexec/oah/libRosettaRuntime` and `oahd` daemon.
- **Filesystem Verification:** Inspects volume flags of target prefix storage directory for `ST_LOCAL` and case-sensitivity (`kTextEncodingMacRoman` / APFS case preservation).

### 4.2 The Anti-Cheat Sentinel (`AntiCheatSentinel`)
A deterministic gatekeeper pattern that intercepts launch requests:
1. Queries target executable and game identifier against the **Compatibility Matrix Database**.
2. If game requires kernel-level drivers (`vgk.sys`, `BEDaisy.sys` for online multiplayer, `EasyAntiCheat.sys` for online queues):
   - **Abort launch before execution.**
   - Emit an informative, user-friendly diagnostic payload:
     - Identification of blocked anti-cheat system.
     - Clear explanation why Ring 0 cannot run in user-mode Wine or on Apple Silicon.
     - Concrete, legal alternative recommendations (e.g. cloud streaming or Windows hardware).
3. If the game has an offline mode that works with anti-cheat disabled (e.g., GTA V Story Mode with `-nobattleye`, or Elden Ring offline):
   - Provide a safe single-click toggle with explicit warnings.

### 4.3 Compatibility Adapter & Runtime Injection
For compatible games, the engine constructs a clean execution sandbox:
- **Environment Variable Layer:**
  - `ROSETTA_ADVERTISE_AVX=1` (for macOS 15+ Sequoia when game utilizes AVX/AVX2).
  - `WINEESYNC=0`, `WINEMSYNC=1` (enforcing Mach-based fast synchronization).
  - `DXMT_LOG_LEVEL=info` (when running open-source DXMT).
  - `WINEDEBUG=-all` (suppressing spammy non-critical Wine traces in production).
- **Prefix Sandboxing:**
  - Keeps game prefixes isolated under `~/Library/Application Support/MachPlay/prefixes/<profile_id>`.
  - Disables Wine drive `Z:` association with root `/` by default to prevent games from scanning personal user directories outside the prefix.

### 4.4 Real-Time Diagnostic Classifier (`DiagnosticClassifier`)
As the game process executes, a streaming pipe monitors `stdout` and `stderr`:
- **Pattern Matchers:**
  - `0x80004005` (Unspecified COM failure -> check DirectX runtime DLLs).
  - `STATUS_ILLEGAL_INSTRUCTION` -> AVX instruction executed on pre-Sequoia macOS or Rosetta flag missing.
  - `Direct3D 12 device creation failed` -> D3DMetal runtime missing or unsupported GPU feature tier.
  - `err:module:import_dll Library ... not found` -> Missing Visual C++ Redistributable runtime.
- **Actionable Advice Engine:** Instead of raw hex error codes, outputs formatted solutions in the UI: *"The game is missing the Microsoft Visual C++ 2015-2022 x64 runtime. Click 'Install Prerequisites' to resolve automatically."*

---

## 5. Technology Stack Rationale

| Layer | Selected Technology | Rationale & Alternatives Considered |
| :--- | :--- | :--- |
| **GUI Frontend** | **Swift 6 / SwiftUI** | Native performance, instant startup, minimal memory consumption (~50MB vs >300MB in Electron), native macOS HIG look & feel, direct access to Metal and CoreAudio APIs. |
| **Core Engine** | **Swift Package (`MachPlayCore`)** | Shared logic between GUI app and CLI. Type-safe async/await concurrency, zero FFI overhead when interfacing with macOS system frameworks. |
| **CLI Utility** | **Swift (`MachPlayCLI`)** | Provides `machplay` terminal commands for headless scripting, automated CI tests, and power-user workflows. |
| **Graphics Translation** | **DXMT (D3D11) & User D3DMetal (D3D12)** | DXMT is fully open-source (LGPL/MIT) and translates directly to Metal 3. D3DMetal is integrated dynamically if present on user machine without violating Apple redistribution license. |
| **CI/CD & Quality** | **GitHub Actions (macOS 14/15 runners)** | Automated `swift test`, SwiftLint, formatting checks, and signed DMG creation. |

---

## 6. Open-Source License Selection

We propose releasing MachPlay Bridge under the **MIT License** (or **Apache License 2.0**):
- **Why Permissive License:** Maximizes developer adoption, allows enterprise contributions, and permits flexible linking with external components.
- **Compatibility with Upstream:**
  - Wine is licensed under **LGPL v2.1+**.
  - DXMT is licensed under **LGPL v2.1+ / MIT**.
  - MoltenVK is licensed under **Apache 2.0**.
  - Running Wine as an external subprocess or interacting with LGPL libraries via dynamic linking fully complies with LGPL terms without forcing the entire host application into a copyleft license.
