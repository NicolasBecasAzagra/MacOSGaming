# Real-Game Validation Procedure & Protocol

This document outlines the standardized technical protocol for validating the execution, stability, and performance of real video games on Apple Silicon macOS using **MacOSGaming**.

---

## 1. Scope & Ethical / Legal Principles

1. **Terms of Service (ToS) Compliance:**
   - Never attempt to bypass or hook online multiplayer anti-cheat platforms (Easy Anti-Cheat, BattlEye, Vanguard, Ricochet).
   - Competitive online multiplayer titles requiring kernel drivers are permanently blocked by MacOSGaming's **Anti-Cheat Sentinel** (`exit code 2`).
   - For titles that support an official single-player offline mode (such as *Elden Ring* or *GTA V Story Mode*), validation must be conducted strictly with explicit offline consent and publisher-supported launch flags (`-nobattleye`, `-offline`, etc.).
2. **No DRM Circumvention:**
   - MacOSGaming does not modify binaries, decrypt protected code, or bypass DRM.
   - Only legally acquired games via official digital stores (Steam, GOG, Epic Games Store) or DRM-free media are validated.
3. **Data Privacy & Sanitization (Zero-Leakage Policy):**
   - Reports generated in `docs/validation/` **must never contain personal usernames (`/Users/<username>`), hardware identifiers, serial numbers, IP addresses, or license keys**.
   - All absolute user paths must be normalized to `~` or abstract placeholders (`<EXTERNAL_STORAGE>`).

---

## 2. Validation Profiles & Workflows

| Game Classification | Typical Example | Execution Layer | Graphics Backend | Anti-Cheat Risk |
|---|---|---|---|---|
| **Native macOS** | Dota 2, Baldur's Gate 3 | Native ARM64 / Rosetta 2 | Metal Native | None (Official publisher support) |
| **Windows DX11 (Indie / Lightweight)** | Vampire Survivors, Hollow Knight, Celeste | Sandboxed Wine-CX | DXMT (D3D11 -> Metal) | None (Single-player / No anti-cheat) |
| **Windows DX11 / DX12 (AAA Offline)** | Elden Ring, GTA V (Story Mode) | Sandboxed Wine-CX | DXMT / DXVK / D3DMetal | Low (Offline single-player only) |
| **Windows Kernel AC (Blocked)** | Valorant, Fortnite | N/A (Blocked) | N/A | **Critical Sentinel Interception** |

---

## 3. Step-by-Step Validation Procedure

### Step 1: System Readiness Diagnostic
Prior to validating any title, execute hardware and runtime inspection:
```bash
swift run macosgaming doctor
```
Verify:
- **Gaming Readiness Score:** >= 60 for lightweight/native titles, >= 75 for AAA graphics.
- **Rosetta 2:** Active and enabled.
- **AVX2 Support:** Active on macOS 15.0+ (Sequoia) for modern AVX2 titles.

### Step 2: Runtime & Dependency Verification
Confirm required compatibility runtimes are available:
```bash
swift run macosgaming setup
```
- Native macOS titles require zero DirectX DLLs or Wine prefixes.
- Windows titles require `Wine-CX` (`brew install --cask gcenx/wine/wine-crossover`) and `DXMT` in `~/Library/Application Support/MacOSGaming/runtimes/dxmt/`.

### Step 3: Steam Library Discovery
Identify the game in your local Steam library:
```bash
swift run macosgaming steam
```
Or inspect verified profile details:
```bash
swift run macosgaming info <game-id>
```

---

### Step 4: Execution Protocol

#### Scenario A: Native macOS Game Validation (Example: Dota 2)
Dota 2 features a native macOS client with Vulkan-to-Metal translation via MoltenVK.
1. Run validation with an execution limit (e.g., 30 seconds) or dry-run simulation:
   ```bash
   swift run macosgaming validate dota-2 --timeout 30
   ```
2. The engine:
   - Resolves `dota2.app` inside the local Steam library.
   - Applies the native profile without initializing Wine or loading DirectX overrides.
   - Captures standard output in real-time.
   - Measures engine startup initialization time (`startup initialization time`).
   - Writes the standardized report to `docs/validation/dota-2-report.md`.

#### Scenario B: Windows DX11 Title with DXMT (Example: Vampire Survivors)
1. Install the game via Steam or download official DRM-free media.
2. If the game is not yet cataloged in `data/profiles/`, specify the explicit executable path:
   ```bash
   swift run macosgaming validate <game-id> --path "/path/to/game.exe" --timeout 45 --retry
   ```
3. The engine:
   - Provisions an isolated Wine prefix in `~/Library/Application Support/MacOSGaming/prefixes/<game-id>`.
   - Injects `WINEMSYNC=1`, `ROSETTA_ADVERTISE_AVX=1`, and `WINEDLLOVERRIDES="d3d11=n,b;dxgi=n,b"`.
   - If DXMT initialization fails, the `--retry` flag automatically attempts fallback settings (built-in DXVK/Wine, msync fastpath disabled).
   - Generates the benchmark report in `docs/validation/<game-id>-report.md`.

#### Scenario C: Title with Offline Consent (Example: Elden Ring)
1. Execute with explicit offline consent:
   ```bash
   swift run macosgaming validate elden-ring --offline --timeout 60
   ```
2. The engine:
   - Verifies with AntiCheat Sentinel that offline mode is safe and supported.
   - Injects the profile's official anti-cheat bypass flags.
   - Boots the game within the sandboxed prefix.

---

## 4. Key Metrics & Pass/Fail Criteria

Each validation report measures:

1. **Startup Initialization Time:**
   - *Excellent:* < 500 ms (Native game or warm Wine prefix).
   - *Acceptable:* 500 ms – 4000 ms (Cold prefix boot and initial shader compilation).
   - *Slow / Investigate:* > 8000 ms.

2. **Framerate (FPS):**
   - Automatically parsed from stdout if the game engine emits performance logs.
   - Estimated from the detected Apple Silicon GPU tier and profile workload when logs lack raw FPS numbers.

3. **Diagnostic Classification (`DiagnosticClassifier`):**
   - 0 critical matches (no unhandled `.sys` driver crashes, missing Visual C++ runtimes, or illegal instruction aborts).

4. **Stability & Clean Exit:**
   - Exit code `0`.
   - In the event of forced timeout, POSIX signal handlers (`SIGINT`/`SIGTERM`) guarantee clean shutdown without prefix registry corruption.
