# Engineering Roadmap & Milestones
# Hoja de Ruta de Ingeniería por Fases — MachPlay Bridge

**Document ID:** `DOC-ROADMAP-001`  
**Project:** MachPlay Bridge  
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

## Phase 1: Monorepo Foundation & Core MVP (Current Target)
- [ ] Initialize monorepo directory layout (`apps/`, `packages/`, `docs/`, `.github/`).
- [ ] Implement `MachPlayCore` Swift Package:
  - `SystemDetector`: CPU (M1-M4), RAM, GPU Metal features, OS version, disk space, and Rosetta 2 status.
  - `AntiCheatSentinel`: Hardware/software policy gatekeeper for unsupported anti-cheat games.
  - `GameProfileRepository`: Embedded JSON database with profiles for popular games.
  - `DiagnosticClassifier`: Basic regex and pattern matcher for Wine / runtime errors.
- [ ] Implement `MachPlayCLI` (`machplay doctor`, `machplay info`, `machplay run`).
- [ ] Create basic GitHub Actions CI pipeline: linting, formatting, automated unit tests.
- [ ] Write professional `README.md` and `LICENSE` (MIT).
- [ ] Verify MVP end-to-end: system detection + diagnostic run on local host.

---

## Phase 2: Prefix Engine & Guided Compatibility Runtime
- [ ] Implement `PrefixManager` for sandbox isolation:
  - Automated Wine prefix creation with zero manual terminal commands.
  - `msync` Mach port synchronization flag enforcement.
  - Configurable `ROSETTA_ADVERTISE_AVX=1` for macOS Sequoia (15.x).
- [ ] Integration with open-source graphics translators:
  - DXMT (DirectX 11 to Metal 3) downloader and linker.
  - Optional D3DMetal adapter (user-guided mounting of local Apple evaluation DMG).
- [ ] Guided installer for legal, open-source or freely available benchmark/test game (e.g. SuperTuxKart Windows build or free open-source test harness).
- [ ] Launch runner with streaming `stdout` / `stderr` pipes and live diagnostic parser.

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
- [ ] One-click library synchronization: imports existing installed games into MachPlay library.
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
