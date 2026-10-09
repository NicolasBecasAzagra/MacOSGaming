# MacOSGaming 🎮

[![Swift](https://img.shields.io/badge/Swift-6.0%2B-F05138.svg?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%20%7C%2015%20(Apple%20Silicon)-000000.svg?logo=apple&logoColor=white)](https://apple.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Architecture](https://img.shields.io/badge/Architecture-ARM64%20(M1%20%7C%20M2%20%7C%20M3%20%7C%20M4)-success.svg)]()

**MacOSGaming** is an enterprise-grade, open-source macOS ecosystem designed to configure, launch, monitor, and diagnose Windows PC games on Apple Silicon Macs safely and legally using established compatibility technologies (Wine, DXMT, and optional local Apple Game Porting Toolkit evaluation runtimes).

---

## 🌟 Key Features

- **⚡ Native Swift 6 Engine (`MacOSGamingCore`):** Built 100% native in Swift with zero-overhead Darwin/Mach kernel bindings, strict compile-time thread safety, and instant startup time.
- **🔍 Automated System Hardware Detector:** Automatically inspects your Apple Silicon chip (M1-M4), performance vs efficiency core counts, Metal GPU capabilities, hardware ray tracing tier, Unified Memory (RAM), Rosetta 2 readiness, and disk space.
- **🛡️ Anti-Cheat Sentinel:** A deterministic safety gate that prevents launching games requiring kernel-level drivers (`vgk.sys`, `BEDaisy.sys`, `EasyAntiCheat.sys`) locally, protecting users from corrupted prefixes, unexpected crashes, and account penalties while educating on legal alternatives.
- **📂 Decoupled Game Profiles (`data/profiles/`):** Game compatibility configurations are isolated into versioned, schema-validated JSON files with required `sources`, `last_verified`, and `confidence_level` attributes.
- **🩺 Intelligent Diagnostic Classifier:** Real-time stream parser that captures game process logs, triages common errors (e.g. missing DirectX/Visual C++ runtimes, AVX unsupported instructions, anti-cheat driver aborts), and produces actionable recommendations.
- **📦 Zero-Vendoring Architecture:** Never bundles pirated game files, cracked DLLs, or proprietary Apple frameworks. External tools are versioned and fetched on demand with user consent, or detected from local installations.

---

## 📊 Compatibility Matrix Summary

| Game | Compatibility Status | Recommended Layer | Anti-Cheat System | Confidence | Verification Date |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Dota 2** | `Native macOS` | Steam Native (MoltenVK -> Metal) | VAC (Native) | Verified | Oct 2026 |
| **League of Legends** | `Native macOS` | Riot Native Mac Client (Metal) | None on Mac (Vanguard on Win only) | Verified | Oct 2026 |
| **Counter-Strike 2 (CS2)** | `Likely Compatible` | CrossOver / GPTK (D3DMetal + msync) | Valve Anti-Cheat (VAC) | Verified *(Note VAC)* | Oct 2026 |
| **Elden Ring** | `Likely Compatible (Offline)` | GPTK / D3DMetal + msync | Easy Anti-Cheat (Offline only) | Verified | Oct 2026 |
| **Grand Theft Auto V** | `Likely Compatible (Story Mode)` | DXMT / D3DMetal (`-nobattleye`) | BattlEye (Online blocked) | Verified | Oct 2026 |
| **Rocket League** | `Requires Windows (Online)` | Wine / DXMT (Offline local only) | Easy Anti-Cheat (Online blocked) | Verified | Oct 2026 |
| **Fortnite** | `Not Supported Locally` | Cloud Gaming (GeForce NOW / Xbox Cloud) | EAC / BattlEye (Kernel Ring-0) | Verified | Oct 2026 |
| **Valorant** | `Not Supported Locally` | Dedicated Physical Windows PC | Riot Vanguard (Ring 0, TPM 2.0) | Verified | Oct 2026 |

> **Why Valorant cannot run on Mac:**  
> Valorant strictly requires Riot Vanguard (`vgk.sys`), a Ring-0 kernel driver, TPM 2.0 hardware attestation, and UEFI Secure Boot. Wine runs exclusively in user mode (Ring 3), macOS kernel (XNU) deprecates third-party kernel drivers, and virtual machines are actively blocked by Vanguard.

---

## 🚀 Getting Started

### Prerequisites
- Apple Silicon Mac (M1, M2, M3, M4 series).
- macOS Sonoma (14.0+) or macOS Sequoia (15.0+ recommended for AVX2 games).
- Xcode 15+ or Command Line Tools (`xcode-select --install`).

### Installation via Swift Package Manager
```bash
# Clone the repository
git clone https://github.com/NicolasBecasAzagra/MacOSGaming.git
cd MacOSGaming

# Build the CLI and Core library
swift build -c release

# Optional: Add to PATH or run directly
.build/release/macosgaming --help
```

---

## 🖥️ Running the Native macOS App (`MacOSGamingApp`)

You can launch the native SwiftUI application directly with Swift Package Manager:

```bash
# Run the SwiftUI app directly in development mode
swift run MacOSGamingApp

# Or compile an optimized release binary and run it
swift build --target MacOSGamingApp -c release
./.build/release/MacOSGamingApp
```

### Application Views:
- 📊 **Dashboard:** Real-time hardware inspection (Apple Silicon chip, cores, unified memory, Metal GPU, Ray Tracing), Rosetta 2 / AVX2 status cards, and the 0–100 Gaming Readiness Score gauge.
- 📚 **Biblioteca (Library):** Automatic Steam library discovery mapped to verified game compatibility profiles, with instant status filtering (`Todos`, `Nativos`, `Compatibles`, `Solo Offline`, `Bloqueados`).
- 🚀 **Lanzador (Launcher):** Launch controls with offline mode consent, live terminal streaming logs, execution cancel button, and real-time Anti-Cheat Sentinel enforcement.
- 🩺 **Diagnósticos (Diagnostics):** Interactive system doctor health checks and real game validation benchmarks with zero data leakage sanitization.
- ⚙️ **Ajustes (Settings):** External runtimes inspection (Wine-CX, DXMT, DXVK, Apple D3DMetal), Steam root paths, and telemetry toggle (**OFF by default**).

---

## 💻 CLI Commands (`macosgaming`)

### 1. Inspect Your System with `macosgaming doctor`
```bash
swift run macosgaming doctor
```
```
+-------------------------------------------------------------+
|                 MACOSGAMING SYSTEM DOCTOR                   |
+-------------------------------------------------------------+
  Apple Silicon Chip:    Apple M3 Pro
  CPU Core Count:        11 cores
  Unified Memory (RAM):  18.0 GB
  Metal GPU:             Apple M3 Pro
  Hardware Ray Tracing:  Yes (M3/M4)
  macOS Version:         15.1.0 (Sequoia 15+ [AVX2 Supported])
  Rosetta 2 Status:      Installed & Active
  Available Disk Space:  214.3 GB
+-------------------------------------------------------------+
  GAMING READINESS SCORE: [ 100 / 100 ]
+-------------------------------------------------------------+
```

### 2. View Profiles and Compatibility
```bash
# List all registered profiles
swift run macosgaming list

# View detailed profile information
swift run macosgaming info valorant
swift run macosgaming info cs2
```

### 3. Run a Sandboxed Test Execution
```bash
# Attempt to run a blocked game (shows educational explanation)
swift run macosgaming test-run valorant

# Run a game permitted in offline mode
swift run macosgaming test-run elden-ring --offline
```

---

## 🧪 Testing & Continuous Integration

```bash
# Run all unit tests
swift test -v
```

GitHub Actions executes the test suite on every pull request on an Apple Silicon macOS runner, checking:
- `SystemDetectorTests`: Hardware inspection and readiness score calculation.
- `AntiCheatSentinelTests`: Deterministic safety gate evaluation and blocking.
- `GameProfileRepositoryTests`: Schema compliance and verified source checking for all profiles.
- `DiagnosticClassifierTests`: Error pattern triage for illegal instructions and missing DLLs.
- `PrefixManagerTests`: Isolated sandbox directory creation.

---

## ⚖️ Legal & Ethical Compliance

- **No Piracy:** We do not provide, host, or distribute games, cracks, or license keys.
- **No Anti-Cheat Tampering:** We strictly do not bypass, disable, or tamper with anti-cheat software.
- **Apple Proprietary Software:** Apple Game Porting Toolkit evaluation binaries (`D3DMetal.framework`) are proprietary to Apple Inc. and are **never** bundled into this repository. Users must obtain evaluation DMGs directly from Apple Developer Downloads.
- See [docs/legal.md](docs/legal.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for full licensing policies.

---

## 🗺️ Roadmap & Documentation
- [Research & State of Mac Gaming](docs/research/state-of-mac-gaming.md)
- [System Architecture Specification](docs/architecture.md)
- [Engineering Roadmap](docs/roadmap.md)
- [Issues & Milestones](docs/issues-and-milestones.md)

---

## 📄 License
Released under the [MIT License](LICENSE).
