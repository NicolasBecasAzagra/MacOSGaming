# Engineering Roadmap & Milestones
# Hoja de Ruta de Ingeniería por Fases — MacOSGaming

**Document ID:** `DOC-ROADMAP-001`  
**Project:** MacOSGaming  
**Version:** 1.0.0-draft  
**Date:** October 2026  

---

## Overview

The engineering roadmap is organized into five structured phases to ensure stability, adherence to legal boundaries, and continuous delivery of verifiable increments.

```
+-------------+     +-------------+     +-------------+     +-------------+     +-------------+
|   PHASE 0   | --> |   PHASE 1   | --> |   PHASE 2   | --> |   PHASE 3   | --> |   PHASE 4   |
| Research &  |     | Foundation  |     |   Prefix    |     | Native App  |     | Diagnostics |
| Architecture|     |    & MVP    |     |   Engine    |     |   (SwiftUI) |     | & Ecosystem |
+-------------+     +-------------+     +-------------+     +-------------+     +-------------+
```

---

## Phase 0: Research & Legal Architectural Grounding (Status: Completed)
- [x] Investigate the state of macOS gaming on Apple Silicon (M1/M2/M3/M4).
- [x] Technical comparison of Wine, CrossOver, GPTK (D3DMetal), DXMT, Parallels, and Cloud Streaming.
- [x] In-depth analysis of anti-cheat restrictions: Ring 0, WHQL drivers, TPM 2.0, Secure Boot, and hypervisor detection.
- [x] Document definitive technical explanation of why Riot Vanguard / Valorant cannot run locally.
- [x] Initial Game Compatibility Matrix covering CS2, Dota 2, Rocket League, Elden Ring, GTA V, Fortnite, Valorant, and League of Legends.
- [x] Publish comprehensive bilingual research document in `docs/research/state-of-mac-gaming.md`.
- [x] Publish technical architecture specification in `docs/architecture.md`.

---

## Phase 1: Monorepo Foundation & Core MVP (Completed)
- [x] Initialize monorepo directory layout (`apps/`, `packages/`, `docs/`, `.github/`).
- [x] Implement `MacOSGamingCore` Swift Package:
  - `SystemDetector`: CPU (M1-M4), RAM, GPU Metal features, OS version, disk space, and Rosetta 2 status.
  - `AntiCheatSentinel`: Hardware/software policy gatekeeper for unsupported anti-cheat games.
  - `GameProfileRepository`: Embedded JSON database with profiles for popular games.
  - `DiagnosticClassifier`: Basic regex and pattern matcher for Wine / runtime errors.
- [x] Implement `MacOSGamingCLI` (`macosgaming doctor`, `macosgaming info`, `macosgaming test-run`).
- [x] Create basic GitHub Actions CI pipeline: linting, formatting, automated unit tests, and source URL validation.
- [x] Write professional `README.md` and `LICENSE` (MIT).
- [x] Verify MVP end-to-end: system detection + diagnostic run on local host.

---

## Phase 2: Steam Library Integration, Full Launch Pipeline & Dependency Setup (Completed)
- [x] Implement `SteamLibraryDetector`:
  - Scans `~/Library/Application Support/Steam` and secondary libraries defined in `libraryfolders.vdf`.
  - Parses `appmanifest_<appid>.acf` to extract app metadata and installation paths.
  - Maps Steam App IDs directly to versioned `GameProfile` entries.
  - CLI command: `macosgaming steam` to discover and list all locally installed Steam games.
- [x] Implement Full Launch Pipeline (`GameLauncher`):
  - CLI command: `macosgaming launch <game-id> [--path <path>] [--offline] [--dry-run]`.
  - Automatic Anti-Cheat Sentinel evaluation (strictly blocks kernel-level anti-cheat before any execution).
  - Prefix sandboxing via `PrefixManager` in `~/Library/Application Support/MacOSGaming/prefixes/<game-id>`.
  - Environment variable injection (`ROSETTA_ADVERTISE_AVX=1`, `WINEMSYNC=1`, `WINEDLLOVERRIDES`).
  - Real-time `stdout`/`stderr` streaming with live `DiagnosticClassifier` crash analysis.
- [x] Guided Dependency Setup (`DependencyManager`):
  - CLI command: `macosgaming setup` to inspect status of Rosetta 2, Wine-CX, DXMT, DXVK-macOS, and D3DMetal.
  - Detailed installation instructions pointing to official upstream sources without in-repo binary vendoring.
- [x] Automated Tests & CI Integration:
  - Unit tests with mock filesystem for Steam library detection (`SteamLibraryDetectorTests`).
  - Unit tests for Sentinel blocking, dry-run simulation, and legal DRM-free binary execution (`GameLauncherTests`).
  - Dedicated CI job `phase-2-tests` in GitHub Actions.

---

## Phase 3: Real-Game Validation, Launcher Hardening & SwiftUI Preparation (Completed)
- [x] Real-Game Validation Protocol & Telemetry:
  - Documented technical validation protocol in `docs/validation/procedure.md` for native macOS, indie DX11 (DXMT), and offline-safe AAA titles.
  - Implemented `GameValidator` and CLI command `macosgaming validate <game-id> [--path <path>] [--timeout <sec>] [--retry] [--dry-run] [--output <path>]`.
  - Automated performance telemetry: startup initialization time, total execution duration, and estimated/measured framerate.
  - Strict privacy sanitization: automated stripping of absolute home paths (`/Users/...`), personal usernames, and storage volume identifiers.
  - Generated reference report: `docs/validation/dota-2-report.md`.
- [x] Launcher Hardening (Signals, Timeouts & Automated Fallback):
  - POSIX signal handling: Graceful shutdown upon `SIGINT` / `SIGTERM` preventing prefix registry corruption.
  - Configurable execution watchdog timer (`timeoutSeconds`) to terminate hanging processes.
  - Automated fallback retry (`autoRetryWithAlternativeConfig`): automatically switches graphics overrides (DXMT -> Wine/DXVK builtin), disables msync, injects AVX flags, and appends fallback parameters upon primary failure.
- [x] SwiftUI Desktop Application Preparation:
  - Designed full desktop layout and wireframes in `docs/ui-mockup.md`: Dashboard, Library, Launcher Inspector, Diagnostics, and Settings.
  - Formally specified `@Observable` ViewModels (`AppViewModel`, `DashboardViewModel`, `LibraryViewModel`, `LaunchViewModel`, `DiagnosticsViewModel`, `SettingsViewModel`) bound reactively to `MacOSGamingCore`.
- [x] Comprehensive Unit Testing:
  - `GameValidatorTests`: validation execution, privacy sanitization verification, and AntiCheat Sentinel enforcement.
  - `ProcessRunnerSignalTests`: timeout watchdog enforcement, clean signal handling, and normal termination.
  - `GameLauncherRetryTests`: automated fallback retry execution and failure reporting.

---

## Phase 4: Native SwiftUI macOS Application & ViewModel Architecture (Completed)
- [x] Native SwiftUI Desktop Target (`MacOSGamingApp`):
  - Created executable application target in `apps/MacOSGamingApp/Sources/MacOSGamingApp/`.
  - Implemented the 5 primary views adhering to `docs/ui-mockup.md`: `DashboardView`, `LibraryView`, `LauncherView`, `DiagnosticsView`, `SettingsView`.
- [x] Fully Reactive MVVM Architecture:
  - Implemented `@Observable` and `@MainActor` ViewModels (`DashboardViewModel`, `LibraryViewModel`, `LaunchViewModel`, `DiagnosticsViewModel`, `SettingsViewModel`).
  - Zero duplicate logic: 100% bound to `MacOSGamingCore` services (`SystemDetector`, `GameLauncher`, `GameProfileRepository`, `DependencyManager`, `SteamLibraryDetector`, `GameValidator`).
  - Non-blocking asynchronous threading: process launches and benchmarks run via detached tasks with thread-safe UI log streaming.
- [x] Core Feature Coverage:
  - **Dashboard:** Gaming Readiness Score gauge (0–100), hardware telemetry (Apple Silicon chip, unified memory, GPU Metal, ray tracing), and Rosetta 2 / AVX2 status cards.
  - **Biblioteca:** Steam game scanning mapped to compatibility profiles, compatibility badges, and multi-state filtering (`Todos`, `Nativos`, `Compatibles`, `Solo Offline`, `Bloqueados`).
  - **Lanzador:** Dynamic profile configuration, live streaming terminal console, cancel button, and immediate Anti-Cheat Sentinel blocking barrier.
  - **Diagnósticos:** Interactive system health doctor and benchmark validation suite.
  - **Ajustes:** External runtime and Steam path verification, strict Zero-Leakage opt-in telemetry toggle (OFF by default).
- [x] Unit Tests & CI Integration:
  - ViewModel unit test suite (`MacOSGamingAppTests`): verifies Dashboard reflects `SystemReport`, Sentinel blocks kernel anti-cheat games, library filtering, and default privacy settings.
  - Added dedicated `phase-4-app-tests` job to `.github/workflows/ci.yml`.

---

## Phase 5: Advanced Diagnostics, Benchmarking & Community Plugins
- [ ] Performance overlay & Metal HUD integration (`MTL_HUD_ENABLED=1`).
- [ ] Benchmarking recorder: frame time percentiles (1% low, 0.1% low, average FPS).
- [ ] Community Plugin System:
  - Schema for third-party game compatibility profiles (`profile.json`).
  - GitHub-based community registry with automated schema validation.
- [ ] Automatic update mechanism via Sparkle framework.
- [ ] Final notarized release packaging with signed DMG installer.
