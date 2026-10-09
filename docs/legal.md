# Legal Policies, Ethics & Compliance Guidelines
# Políticas Legales, Ética y Guías de Cumplimiento — MacOSGaming

**Project:** MacOSGaming  
**Date:** October 2026  
**Status:** Mandatory Engineering Policy  

---

## 1. Core Commitment & Scope

MacOSGaming is an open-source compatibility management utility for macOS. The project's mission is to provide an accessible, high-performance orchestration layer to execute legitimately owned PC software on Apple Silicon hardware using legal compatibility technologies.

To protect the integrity of the project, users, and contributors, the following principles are strictly enforced.

---

## 2. Zero-Tolerance Copyright & Anti-Piracy Policy

1. **No Bundling of Protected Software:** MacOSGaming will never host, bundle, distribute, or facilitate the unauthorized downloading of:
   - Copyrighted game executables, assets, or data archives.
   - Proprietary DLLs extracted from commercial operating systems without license.
   - Product keys, serial generators, or activation cracks.
2. **Official Storefronts Exclusively:** The platform strictly interacts with official, legitimate digital game distribution platforms (such as Steam, Epic Games Store, GOG Galaxy, and Battle.net) or legitimate DRM-free media owned by the end user.
3. **No DRM Circumvention:** MacOSGaming does not circumvent, crack, or disable Digital Rights Management (DRM) mechanisms (such as Denuvo, Steam DRM, or Epic Online Services authentication).

---

## 3. Anti-Cheat Integrity & Terms of Service Adherence

1. **Absolute Anti-Cheat Non-Interference:**
   MacOSGaming does **not** provide, promote, or tolerate:
   - Bypasses, memory injections, or signature spoofing for kernel-level anti-cheats (including Riot Vanguard, Easy Anti-Cheat, BattlEye, and Activision Ricochet).
   - Hooking or patching anti-cheat drivers (`vgk.sys`, `BEDaisy.sys`, `EasyAntiCheat.sys`).
   - Countermeasures designed to evade anti-cheat telemetry or virtual machine detection.
2. **The "Sentinel" Safety Gate:**
   When an application protected by an incompatible anti-cheat system (such as *Valorant* or *Fortnite*) is requested:
   - MacOSGaming halts launch before process creation.
   - It informs the user transparently that the title cannot be safely or legally executed locally on macOS.
   - It recommends valid alternatives, such as using an authorized cloud streaming service or a dedicated Windows computer.
3. **Offline Modes with Publisher Support:**
   Where game publishers officially provide an offline or anti-cheat-free mode (e.g., Grand Theft Auto V Story Mode launched with `-nobattleye`), MacOSGaming allows launching this specific mode with clear educational notices to the user.

---

## 4. Policy Regarding Apple Proprietary Software & D3DMetal

1. **No Redistribution:** Apple’s Game Porting Toolkit and its underlying `D3DMetal.framework` / `libd3dshared.dylib` components are proprietary software covered by Apple’s *Game Porting Toolkit Evaluation License Agreement*.
2. **Developer-Only Local Detection:**
   - MacOSGaming does not download, mirror, or repackage Apple Game Porting Toolkit binaries.
   - The software only contains detection routines to identify if the user—in their personal capacity as a registered Apple Developer—has downloaded and mounted the official evaluation DMG from Apple Developer Downloads.
3. **Open-Source Priority:**
   - For DirectX 11 translation, the project defaults to **DXMT**, a fully open-source translation layer licensed under LGPL v2.1+ / MIT.

---

## 5. Trademark Disclaimer

- Apple, macOS, Metal, Apple Silicon, M1, M2, M3, M4, and Rosetta are registered trademarks of Apple Inc.
- Windows, DirectX, and Direct3D are registered trademarks of Microsoft Corporation.
- Valve, Steam, and Counter-Strike are registered trademarks of Valve Corporation.
- Riot Games, Valorant, and League of Legends are registered trademarks of Riot Games, Inc.
- Epic Games, Fortnite, and Unreal Engine are registered trademarks of Epic Games, Inc.
- Rockstar Games and Grand Theft Auto are registered trademarks of Take-Two Interactive Software, Inc.
- Elden Ring is a trademark of FromSoftware, Inc. and Bandai Namco Entertainment Inc.

The use of these names in this project is strictly for identification, compatibility reference, and descriptive purposes under fair use doctrine. MacOSGaming is an independent open-source project and is not affiliated with, endorsed by, or sponsored by any of the trademark owners listed above.
