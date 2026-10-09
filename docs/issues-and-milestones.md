# Project Milestones & Initial Issues Backlog
# Hitos del Proyecto y Backlog Inicial de Issues — MacOSGaming

**Project:** MacOSGaming  
**Date:** October 2026  
**Tracking System:** GitHub Milestones & Issues  

---

## 1. Project Milestones

| Milestone | Title | Target Phase | Status | Objective |
| :--- | :--- | :--- | :--- | :--- |
| **MS-0** | Research, Architecture & Legal Boundaries | Phase 0 | **Completed** | Technical research in `docs/research/`, architecture spec, roadmap, and verified sources. |
| **MS-1** | Foundation, Core Engine & CLI MVP | Phase 1 | **In Progress** | Swift 6 monorepo, `MacOSGamingCore`, `MacOSGamingCLI` (`doctor`, `test-run`), unit tests, and GitHub Actions CI. |
| **MS-2** | Prefix Sandbox & Guided Runtimes | Phase 2 | Scheduled | Sandbox isolation under `~/Library/Application Support/MacOSGaming/`, DXMT installer, and msync enforcement. |
| **MS-3** | Native SwiftUI Desktop App | Phase 3 | Scheduled | Modern macOS HIG desktop application with glassmorphic dashboard, game library, and real-time logs. |
| **MS-4** | Local Launchers & Library Auto-Import | Phase 4 | Scheduled | Scanners for macOS Steam, Windows Steam bottles, Epic Games, GOG, and Battle.net manifests. |
| **MS-5** | Benchmarking & Community Profiles | Phase 5 | Scheduled | Metal HUD telemetry, frame-time percentiles (1% low), and community profile registry. |

---

## 2. Initial Issues Backlog

### Phase 1 Issues (Milestone MS-1)

#### Issue #1: `feat(repo): initialize Swift 6 monorepo layout and GitHub Actions CI`
- **Description:** Setup root `Package.swift` with multi-target configuration (`MacOSGamingCore`, `MacOSGamingCLI`, and `MacOSGamingCoreTests`). Configure `.github/workflows/ci.yml` running on macOS runner with `swift build` and `swift test`.
- **Labels:** `build`, `ci`, `phase-1`

#### Issue #2: `feat(core): implement SystemDetector for Apple Silicon and Darwin`
- **Description:** Query kernel `sysctl` for CPU brand string (M1, M2, M3, M4), core configuration, Metal GPU capabilities via `MTLCopyAllDevices()`, unified memory footprint, and Rosetta 2 runtime readiness.
- **Labels:** `core`, `phase-1`

#### Issue #3: `feat(core): implement AntiCheatSentinel and ProfileRepository from data/profiles/`
- **Description:** Load and parse JSON game profiles from `data/profiles/`. Deterministically intercept and block launch requests for kernel-level anti-cheat titles (`valorant`, `fortnite`), emitting educational diagnostic explanations.
- **Labels:** `security`, `core`, `phase-1`

#### Issue #4: `feat(core): implement DiagnosticClassifier for real-time log triage`
- **Description:** Pattern-match common Wine, DirectX, and Rosetta runtime crash errors from process streams (e.g., missing VC++ redistributable, missing DirectX components, AVX unsupported instruction) and output actionable resolution advice.
- **Labels:** `diagnostics`, `core`, `phase-1`

#### Issue #5: `feat(cli): implement MacOSGamingCLI ('doctor', 'info', 'test-run')`
- **Description:** Create headless CLI tool `macosgaming` with subcommands:
  - `doctor`: Print complete hardware suitability and readiness report.
  - `info <game-id>`: Print game profile compatibility status, sources, and anti-cheat requirements.
  - `test-run`: Execute a legal, open-source or freely available test binary inside an isolated sandbox, streaming and classifying logs.
- **Labels:** `cli`, `phase-1`

#### Issue #6: `test(core): add comprehensive unit test suite`
- **Description:** Unit tests for `SystemDetector` parsing, `AntiCheatSentinel` blocking/allowing, `ProfileRepository` JSON schema validation, and `DiagnosticClassifier` regex error classification.
- **Labels:** `tests`, `phase-1`
