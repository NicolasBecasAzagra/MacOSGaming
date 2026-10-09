# Technical Architecture Specification
# Arquitectura Técnica del Sistema — MacOSGaming

**Document ID:** `DOC-ARCH-001`  
**Project:** MacOSGaming (macOS Open Source Gaming Compatibility Ecosystem)  
**Status:** Proposed Architecture / En Revisión Técnica  
**Date:** October 2026  
**Lead Architect:** Engineering Team  

---

## 1. Executive Vision & Design Philosophy

**MacOSGaming** is an enterprise-grade, open-source macOS desktop application and modular engine designed to configure, launch, monitor, and diagnose Windows games on Apple Silicon (M1/M2/M3/M4) computers running macOS Sonoma (14.x) and macOS Sequoia (15.x/16.x).

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
│   └── MacOSGamingApp/            # Native macOS SwiftUI App
│       ├── App/
│       │   ├── MacOSGamingApp.swift # App lifecycle & NavigationSplitView
│       │   └── MenuCommands.swift # Menu bar shortcuts & system actions
│       ├── Views/
│       │   ├── Dashboard/         # System specs, chip telemetry, readiness
│       │   ├── Library/           # Installed games & launcher integration
│       │   ├── GameDetail/        # Game profile settings, graphics toggles
│       │   ├── Diagnostics/       # Live logs, log analysis, diagnostic export
│       │   └── Settings/          # Prefix management & runtime selector
│       └── Resources/             # Assets, Icons, Localizations (en, es)
├── packages/
│   ├── MacOSGamingCore/           # Swift Engine Package
│   │   ├── Sources/MacOSGamingCore/
│   │   │   ├── SystemDetector/    # Chip (M1-M4), RAM, GPU, OS, Rosetta status
│   │   │   ├── Compatibility/     # Game Profiles DB, Anti-Cheat Sentinel
│   │   │   ├── PrefixManager/     # Wine/Darwin prefix creation & isolation
│   │   │   ├── Runner/            # Subprocess runner, environment injector
│   │   │   ├── Diagnostics/       # Real-time log parser & pattern classifier
│   │   │   └── Launchers/         # Steam, Epic, GOG local scanner
│   │   └── Tests/MacOSGamingCoreTests/
│   └── MacOSGamingCLI/            # Headless CLI for developers & automation
│       └── Sources/MacOSGamingCLI/ # 'macosgaming doctor', 'macosgaming run', etc.
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
|                              CORE ENGINE (MacOSGamingCore)                        |
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

#### Gaming Readiness Score Rubric (0 – 100)
The readiness score evaluates hardware suitability for modern Windows games running under translation layers (see complete specification in [Gaming Readiness Score Docs](gaming-readiness-score.md)):
- **Apple Silicon:** +30 pts (M1-M4 unified architecture, Metal 3/3.1).
- **Unified Memory (RAM):**
  - $\ge$ 32 GB: +25 pts (Tier 1: Enthusiast headroom, 4K textures, zero swap).
  - 16 GB to < 32 GB: +20 pts (Tier 2: Recommended baseline for modern 3D games).
  - 8 GB to < 16 GB: **-10 pts (Penalty)** (Severe UMA bottleneck: CPU and GPU contend for ~4 GB usable memory after macOS overhead).
  - < 8 GB: **-20 pts (Severe Penalty)** (Insufficient for OS + translation runtimes).
- **macOS Version & AVX2:**
  - macOS $\ge$ 15 (Sequoia / Tahoe / later): +20 pts (AVX2 supported via Rosetta 2).
  - macOS < 15: +5 pts (Limited to SSE4.2; AVX instructions crash).
- **Rosetta 2 Runtime:** +15 pts if installed and active.
- **Free Disk Space:** +10 pts ($\ge$ 50 GB), +5 pts (25–50 GB), 0 pts (< 25 GB).

$$\text{Final Score} = \min(100, \max(0, \text{Points}))$$

### 4.2 The Anti-Cheat Sentinel & Game Profiles (`data/profiles/`)
The engine decouples game compatibility definitions from binary code by reading versioned JSON definitions located in `data/profiles/`.
Each profile conforms to a strict schema with required metadata:
- `id`: Unique game identifier (e.g. `elden-ring`, `valorant`, `cs2`, `dota-2`).
- `name`: Display name of the game.
- `compatibility_status`: `native_macos`, `likely_compatible`, `requires_windows`, `not_supported`.
- `confidence_level`: `verified`, `probable`, `hypothesis`.
- `last_verified`: Date of verification (e.g. `2026-10-09`).
- `sources`: Array of verified citations, official publisher FAQs, or commit references.
- `anti_cheat`: Details of the anti-cheat system (`kernel_ring0`, `userspace`, `none`, or `offline_bypass_available`).
- `launch_policy`: Action to take (`allow`, `block_kernel_anticheat`, `offline_only_prompt`).
- `environment_variables`: Recommended flags (e.g., `ROSETTA_ADVERTISE_AVX=1`, `WINEMSYNC=1`).
- `graphics_backend`: Recommended translation backend (`dxmt`, `d3dmetal_user_provided`, `dxvk`, `metal_native`).

### 4.3 External Dependency Management (Zero In-Repo Vendoring)
To ensure full legal compliance and keep the repository lightweight:
- **No Vendoring:** Wine, DXMT, DXVK, and Apple D3DMetal are **NEVER** stored or checked into this repository.
- **Versioned Downloader / Detector:**
  - Open-source packages (DXMT, Wine-CX builds) are downloaded on user request with SHA-256 verification directly from upstream GitHub releases into `~/Library/Application Support/MacOSGaming/runtimes/`.
  - Apple's proprietary D3DMetal is **never** downloaded automatically; the user must obtain the evaluation DMG directly from Apple Developer Downloads, and MacOSGaming merely detects the user's locally mounted path.
- **Prefix Isolation:** Prefixes reside strictly in `~/Library/Application Support/MacOSGaming/prefixes/<profile_id>`, isolating Windows registry hives and virtual drives from host system directories.

### 4.4 Real-Time Diagnostic Classifier (`DiagnosticClassifier`)
As the game process executes, a streaming pipe monitors `stdout` and `stderr`:
- **Pattern Matchers:**
  - `0x80004005` (Unspecified COM failure -> check DirectX runtime DLLs).
  - `STATUS_ILLEGAL_INSTRUCTION` -> AVX instruction executed on pre-Sequoia macOS or Rosetta flag missing.
  - `Direct3D 12 device creation failed` -> D3DMetal runtime missing or unsupported GPU feature tier.
  - `err:module:import_dll Library ... not found` -> Missing Visual C++ Redistributable runtime.
- **Actionable Advice Engine:** Instead of raw hex error codes, outputs formatted solutions in the UI: *"The game is missing the Microsoft Visual C++ 2015-2022 x64 runtime. Click 'Install Prerequisites' to resolve automatically."*

### 4.5 Steam Library Detection Engine (`SteamLibraryDetector`)
To automatically bridge installed games without requiring user-side manual file path browsing:
- **Library Discovery:** Resolves primary Steam installation at `~/Library/Application Support/Steam` and secondary library drives configured in `steamapps/libraryfolders.vdf`.
- **Manifest Parsing:** Parses `appmanifest_<appid>.acf` key-value pairs (AppID, installation directory, StateFlags).
- **Executable Locator:** Scans `<library>/steamapps/common/<installdir>` for primary Windows `.exe` binaries or native `.app` bundles, filtering out uninstallation helpers, crash reporters, and redistributable setup utilities.
- **Profile Association:** Automatically links discovered Steam App IDs (e.g. `730` for CS2, `1245620` for Elden Ring) to `GameProfile` entries.

### 4.6 Full Launch Pipeline (`GameLauncher`)
The launch coordinator executes the full lifecycle of a Windows or native game under macOS:
1. **Sentinel Pre-flight Gate:** The `AntiCheatSentinel` evaluates the game profile. If a title mandates kernel-level anti-cheat (e.g., Vanguard in Valorant or BattlEye in Fortnite), execution is strictly rejected before spawning any sub-process.
2. **Binary Resolution:** Resolves target executable from Steam detection or user-provided `--path`.
3. **Prefix Sandboxing:** `PrefixManager` provisions or re-uses the game's isolated directory in `~/Library/Application Support/MacOSGaming/prefixes/<game_id>`.
4. **Environment Assembly:** Injects `WINEPREFIX`, `ROSETTA_ADVERTISE_AVX=1` (macOS 15+), `WINEMSYNC=1`, and DLL overrides (`d3d11=n,b;dxgi=n,b` for DXMT).
5. **Streaming Subprocess & Diagnostics:** `ProcessRunner` executes the process (or dry-run simulation), streaming stdout/stderr in real-time to the console and piping output to `DiagnosticClassifier` for immediate error pattern detection.

### 4.7 Dependency & Runtime Manager (`DependencyManager`)
Enforces legal and architectural separation between host code and third-party runtimes:
- **Zero Vendoring:** No third-party binaries (Wine, DXMT, DXVK, D3DMetal) are tracked in git.
- **Runtime Directory:** Manages user runtimes under `~/Library/Application Support/MacOSGaming/runtimes/` (`wine`, `dxmt`, `dxvk`).
- **Interactive & Headless Setup:** `macosgaming setup` checks status of Rosetta 2, Wine-CX, DXMT, DXVK-macOS, and local D3DMetal DMG mounts, providing exact official download URLs and installation commands.

---

## 5. Technology Stack Rationale

| Layer | Selected Technology | Rationale & Alternatives Considered |
| :--- | :--- | :--- |
| **GUI Frontend** | **Swift 6 / SwiftUI** | Native performance, instant startup, minimal memory consumption (~50MB vs >300MB in Electron), native macOS HIG look & feel, direct access to Metal and CoreAudio APIs. |
| **Core Engine** | **Swift Package (`MacOSGamingCore`)** | Shared logic between GUI app and CLI. Type-safe async/await concurrency, zero FFI overhead when interfacing with macOS system frameworks. |
| **CLI Utility** | **Swift (`MacOSGamingCLI`)** | Provides `macosgaming` terminal commands for headless scripting, automated CI tests, and power-user workflows. |
| **Graphics Translation** | **DXMT (D3D11) & User D3DMetal (D3D12)** | DXMT is fully open-source (LGPL/MIT) and translates directly to Metal 3. D3DMetal is integrated dynamically if present on user machine without violating Apple redistribution license. |
| **CI/CD & Quality** | **GitHub Actions (macOS 14/15 runners)** | Automated `swift test`, SwiftLint, formatting checks, and signed DMG creation. |

---

## 6. Open-Source License Selection

We propose releasing MacOSGaming under the **MIT License** (or **Apache License 2.0**):
- **Why Permissive License:** Maximizes developer adoption, allows enterprise contributions, and permits flexible linking with external components.
- **Compatibility with Upstream:**
  - Wine is licensed under **LGPL v2.1+**.
  - DXMT is licensed under **LGPL v2.1+ / MIT**.
  - MoltenVK is licensed under **Apache 2.0**.
  - Running Wine as an external subprocess or interacting with LGPL libraries via dynamic linking fully complies with LGPL terms without forcing the entire host application into a copyleft license.
