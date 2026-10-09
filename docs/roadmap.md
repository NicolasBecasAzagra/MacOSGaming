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

## Phase 3: Native macOS SwiftUI Desktop Application
- [ ] Build clean, modern macOS desktop app using SwiftUI 6:
  - Modern `NavigationSplitView` architecture.
  - Native dark-mode and glassmorphic materials (`.ultraThinMaterial`).
  - System specs and compatibility readiness score dashboard.
  - Library view with game artwork and status badges (`Native`, `Compatible`, `Blocked Anti-Cheat`).
- [ ] Game detail inspector:
  - Graphics backend switcher (DXMT vs D3DMetal vs DXVK).
  - Environment variable editor.
  - Offline mode toggles for games with separable anti-cheat (e.g. GTA V Story Mode).
- [ ] Live Diagnostic Console:
  - Embedded terminal log viewer with syntax highlighting and auto-scroll.
  - One-click copy and anonymized diagnostic report export.

---

## Phase 4: Launcher Scanner & Auto-Import
- [ ] Auto-detection of local launchers:
  - macOS Steam and Windows Steam bottle detection.
  - Epic Games Store manifests scanner (`.item` files).
  - GOG Galaxy library detection.
  - Battle.net installation scanner.
- [ ] One-click library synchronization: imports existing installed games into MacOSGaming library.
- [ ] Custom game importer: drag-and-drop `.exe` installer with automatic profile matching.

---

## Phase 5: Advanced Diagnostics, Benchmarking & Community Plugins
- [ ] Performance overlay & Metal HUD integration (`MTL_HUD_ENABLED=1`).
- [ ] Benchmarking recorder: frame time percentiles (1% low, 0.1% low, average FPS).
- [ ] Community Plugin System:
  - Schema for third-party game compatibility profiles (`profile.json`).
  - GitHub-based community registry with automated schema validation.
- [ ] Automatic update mechanism via Sparkle framework.
- [ ] Final notarized release packaging with signed DMG installer.
