# MacOSGaming 🎮

[![CI](https://github.com/NicolasBecasAzagra/MacOSGaming/actions/workflows/ci.yml/badge.svg)](https://github.com/NicolasBecasAzagra/MacOSGaming/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/NicolasBecasAzagra/MacOSGaming?color=brightgreen&logo=github)](https://github.com/NicolasBecasAzagra/MacOSGaming/releases)
[![Pages](https://img.shields.io/badge/Docs%20%26%20Matrix-GitHub%20Pages-blue?style=flat-square&logo=githubpages)](https://nicolasbecasazagra.github.io/MacOSGaming/)
[![Game Profiles](https://img.shields.io/badge/Profiles-8%20Cataloged-blue?style=flat-square&logo=apple)](https://nicolasbecasazagra.github.io/MacOSGaming/compatibility.html)
[![Confidence](https://img.shields.io/badge/Confidence-8%20Verified-brightgreen?style=flat-square&logo=checkmarx)](https://nicolasbecasazagra.github.io/MacOSGaming/compatibility.html)
[![Playable on Mac](https://img.shields.io/badge/Playable-5%20Supported-success?style=flat-square&logo=speedtest)](https://nicolasbecasazagra.github.io/MacOSGaming/compatibility.html)
[![Blocked by Anti-Cheat](https://img.shields.io/badge/Blocked-2%20Kernel%20Anti--Cheat-critical?style=flat-square&logo=shield)](https://nicolasbecasazagra.github.io/MacOSGaming/compatibility.html)
[![Swift](https://img.shields.io/badge/Swift-5.10%20%7C%206.0-F05138.svg?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%20%7C%2015%20(Apple%20Silicon)-000000.svg?logo=apple&logoColor=white)](https://apple.com)
[![Architecture](https://img.shields.io/badge/Architecture-ARM64%20(M1%20%7C%20M2%20%7C%20M3%20%7C%20M4)-success.svg)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**MacOSGaming** is an enterprise-grade, open-source native macOS ecosystem engineered to configure, launch, monitor, and diagnose Windows PC and native games on Apple Silicon Macs safely, legally, and with optimal performance using battle-tested compatibility runtimes (Wine-CX, DXMT, DXVK-macOS, and local user-provided Apple Game Porting Toolkit evaluation runtimes).

🌐 **Online Documentation & Live Compatibility Matrix:** [https://nicolasbecasazagra.github.io/MacOSGaming/](https://nicolasbecasazagra.github.io/MacOSGaming/)

---

## 🖥️ Native SwiftUI User Interface

<p align="center">
  <img src="docs/screenshots/dashboard_preview.png" alt="MacOSGaming Dashboard UI" width="850">
</p>
<p align="center">
  <em>System Dashboard featuring real-time Gaming Readiness Score, Apple Silicon hardware telemetry, and Rosetta 2 / AVX2 instruction set inspection.</em>
</p>

<p align="center">
  <img src="docs/screenshots/launcher_preview.png" alt="MacOSGaming Launcher & Sentinel UI" width="850">
</p>
<p align="center">
  <em>Game Launcher with live streaming terminal logs, safe offline launch consent, and active Anti-Cheat Sentinel protection.</em>
</p>

---

## 🌟 Key Features

- **⚡ 100% Native Swift 6 Engine (`MacOSGamingCore`):** Reactive MVVM architecture powered by `@Observable` and `@MainActor`, low-level Mach/Darwin kernel bindings, and a tiny memory footprint (<60 MB RAM vs >400 MB in Electron-based launchers).
- **🔍 Hardware Detector & Gaming Readiness Score:** Automated inspection of Apple Silicon chip tier (M1–M4), CPU core count, unified memory contention (RAM), Metal GPU, hardware Ray Tracing, disk space, and Rosetta 2 / AVX2 availability (macOS 15+).
- **🛡️ Anti-Cheat Sentinel Gate:** A deterministic pre-flight security barrier that strictly intercepts and halts games requiring kernel-level Ring-0 drivers (`vgk.sys`, `BEDaisy.sys`, `EasyAntiCheat.sys`), preventing system panics and account bans while detailing legal alternatives.
- **📚 Complete Steam Library Discovery (`SteamLibraryDetector`):** Automated scanner detecting all installed Steam games across primary and secondary storage libraries. Displays an **"Optimized"** badge for profiled games and a **"Generic/Unprofiled"** badge for other titles with an instant **"Request Profile"** action pre-filling GitHub issue templates.
- **📦 Transparent Dependency Manager with Real Progress:** Per-game dependency resolution modal displaying required runtimes (Wine-CX, DXMT, DXVK, VC++ Redistributable), file sizes in MB, official sources, and selection checkboxes. Downloads using `URLSessionDownloadDelegate` with real progress bars, enforces strict user confirmation, and persists sandbox prefix manifests (`installed_dependencies.json`) to eliminate redundant re-downloads.
- **📂 Decoupled Game Profiles (`data/profiles/`):** Version-controlled JSON schema profiles backed by live HTTP 200 source URLs, verification timestamps, and confidence ratings.
- **🌐 Interactive Compatibility Matrix:** Generated static web matrix with instant search, status filtering, and anti-cheat categorization available directly on [GitHub Pages](https://nicolasbecasazagra.github.io/MacOSGaming/compatibility.html).
- **🩺 Real-Time Diagnostic Classifier:** Intelligent log pattern matching that detects DirectX initialization faults, unsupported AVX calls, and missing Visual C++ runtime DLLs.
- **🔒 Zero-Leakage Privacy Policy:** Automated telemetry sanitization that anonymizes absolute filesystem paths (`/Users/...` to `~`) and usernames. Telemetry is strictly opt-in and disabled by default.

---

## ⚡ Quick Start

### 1. Download Pre-built Release (Recommended)
You can directly download pre-compiled Apple Silicon binaries without compiling from source:

#### 📱 Native Desktop App (GUI)
Download the `.app` bundle, extract, and launch (supports double-click launch and macOS Dock integration):
```bash
# Download, extract, and open MacOSGamingApp:
curl -L -O https://github.com/NicolasBecasAzagra/MacOSGaming/releases/latest/download/MacOSGamingApp-v0.1.1-macos-arm64.zip
unzip MacOSGamingApp-v0.1.1-macos-arm64.zip
open MacOSGamingApp.app
```

#### 💻 Standalone CLI Tool (`macosgaming`)
Download the standalone command-line executable for terminal workflows and automated scripting:
```bash
# Download, extract, and run macosgaming doctor:
curl -L -O https://github.com/NicolasBecasAzagra/MacOSGaming/releases/latest/download/macosgaming-v0.1.1-macos-arm64.tar.gz
tar -xzvf macosgaming-v0.1.1-macos-arm64.tar.gz
chmod +x macosgaming
./macosgaming doctor
```

---

### 2. Build & Run from Source (Developers)

#### Prerequisites
- Mac with Apple Silicon processor (M1, M2, M3, M4 or Pro/Max/Ultra variants).
- macOS Sonoma (14.0+) or macOS Sequoia (15.0+ recommended).
- Xcode 15+ or Command Line Tools installed (`xcode-select --install`).

#### Clone & Build
```bash
# Clone the repository
git clone https://github.com/NicolasBecasAzagra/MacOSGaming.git
cd MacOSGaming

# Build all products in Release mode
swift build -c release
```

#### Run Native Desktop App from Source
```bash
# Run the application directly with Swift Package Manager:
swift run MacOSGamingApp

# Or launch the optimized production binary:
swift build --product MacOSGamingApp -c release
./.build/release/MacOSGamingApp
```

#### Run CLI Tool from Source
```bash
# Inspect system hardware and calculate Gaming Readiness Score:
swift run macosgaming doctor

# Interactive dependency setup assistant (Rosetta 2, Wine, DXMT, DXVK):
swift run macosgaming setup

# Automatically discover games installed in local Steam library:
swift run macosgaming steam

# Simulate launch pipeline with an isolated Wine prefix (Dry-Run):
swift run macosgaming launch elden-ring --offline --dry-run

# Benchmark performance and generate sanitized report:
swift run macosgaming validate dota-2 --dry-run
```

---

## 🎮 Supported Games & Compatibility Matrix

Explore our live interactive matrix at **[https://nicolasbecasazagra.github.io/MacOSGaming/compatibility.html](https://nicolasbecasazagra.github.io/MacOSGaming/compatibility.html)**.

| Game | Compatibility Status | Recommended Runtime | Anti-Cheat | Confidence Level |
| :--- | :--- | :--- | :--- | :--- |
| **Dota 2** | `Native macOS` | Steam Native (Metal) | VAC (macOS Native) | Verified |
| **League of Legends** | `Native macOS` | Riot Native Mac Client (Metal) | None on Mac (Vanguard Windows-only) | Verified |
| **Counter-Strike 2** | `Likely Compatible` | CrossOver / GPTK (D3DMetal + msync) | Valve Anti-Cheat (VAC) | Verified *(VAC Session Drops)* |
| **Elden Ring** | `Likely Compatible (Offline)` | GPTK / DXMT + msync | EAC (Offline single-player only) | Verified |
| **Grand Theft Auto V** | `Likely Compatible (Story Mode)`| DXMT / D3DMetal (`-nobattleye`) | BattlEye (Multiplayer blocked) | Verified |
| **Rocket League** | `Requires Windows (Online)` | Wine / DXMT (Local matches & training) | EAC (Multiplayer blocked) | Verified |
| **Fortnite** | `Not Supported Locally` | Cloud Gaming (GeForce NOW / Xbox Cloud) | EAC / BattlEye (Kernel Ring-0) | Verified |
| **Valorant** | `Not Supported Locally` | Dedicated Physical Windows PC | Riot Vanguard (Ring-0 / TPM 2.0) | Verified |

> **Technical Note on Kernel Anti-Cheat (Ring-0):**  
> Competitive titles such as Valorant strictly mandate kernel drivers (`vgk.sys`), TPM 2.0, and UEFI Secure Boot. Because compatibility layers (Wine/Proton) operate strictly within user space (Ring 3), and macOS does not permit arbitrary third-party kernel extensions, games requiring kernel-level drivers **cannot execute locally on macOS**.

---

## 🧪 Testing & Code Quality

The repository includes comprehensive unit and integration test suites:

```bash
# Run the entire test suite:
swift test -v

# Run app ViewModel tests:
swift test --filter MacOSGamingAppTests -v

# Run compatibility generator tests:
swift test --filter CompatibilityMatrixGeneratorTests -v

# Validate profile schema and live HTTP 200 source URLs:
./scripts/validate_sources.sh
```

GitHub Actions workflows automatically validate on every pull request:
- `build-and-test`: Cross-compilation and unit test execution on Apple Silicon macOS.
- `phase-2-tests`: Steam library detection and isolated launch pipeline tests.
- `phase-3-tests`: POSIX signal management, watchdog timeouts, and telemetry sanitization.
- `phase-4-app-tests`: Native SwiftUI application compilation and ViewModel tests.
- `validate-sources`: Live HTTP 200 verification for all profile source links.
- `pages`: Automated publication of `docs/website/` to GitHub Pages.

---

## 🗺️ Engineering Roadmap

The project follows a structured engineering roadmap with verified phase deliverables:
- ✅ **Phase 0:** Technical research and legal foundation ([docs/research/state-of-mac-gaming.md](docs/research/state-of-mac-gaming.md)).
- ✅ **Phase 1:** Monorepo architecture, `MacOSGamingCore`, and CLI MVP.
- ✅ **Phase 2:** Steam integration, launch pipeline, and dependency management.
- ✅ **Phase 3:** Real-world game validation protocols, signal handling, and UI mockups.
- ✅ **Phase 4:** Native macOS desktop app with SwiftUI and reactive MVVM architecture.
- ✅ **Phase 5:** Public release v0.1.1, website showcase, and contributing guidelines.
- 🚀 **Phase 6:** Community validation, issue forms, GitHub Pages, and compatibility matrix automation.

Read the complete engineering roadmap in **[docs/roadmap.md](docs/roadmap.md)**.

---

## 🤝 Community & Contributing

Community contributions and game test reports are warmly welcome! Please review our **[Contributing Guidelines (CONTRIBUTING.md)](CONTRIBUTING.md)**:
- [Submit a Game Compatibility Report](https://github.com/NicolasBecasAzagra/MacOSGaming/issues/new?template=game_report.yml)
- [Request a New Game Profile](https://github.com/NicolasBecasAzagra/MacOSGaming/issues/new?template=profile_request.yml)
- [Report a Bug or Crash](https://github.com/NicolasBecasAzagra/MacOSGaming/issues/new?template=bug_report.yml)

---

## ⚖️ Legal & Ethical Compliance

- **Zero Piracy:** We do not host, distribute, or facilitate downloads of game files, cracks, or illegal licenses.
- **Zero Anti-Cheat Tampering:** We never modify, hook, bypass, or patch multiplayer anti-cheat software.
- **Apple Proprietary Software:** Apple Game Porting Toolkit evaluation binaries (`D3DMetal.framework`) remain the exclusive intellectual property of Apple Inc. and are **never** distributed by this repository.
- Consult [docs/legal.md](docs/legal.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for full legal disclosures.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
