# Contributing Guidelines 🤝

Thank you for your interest in contributing to **MacOSGaming**! This project is open source under the [MIT License](LICENSE) and aims to deliver a legal, transparent, and high-performance native platform for configuring, launching, and diagnosing games on Apple Silicon macOS.

To ensure enterprise-grade code quality, security, and ethical standards, all contributors are requested to follow these guidelines.

---

## 🛠️ 1. Development Environment Setup

### Prerequisites
- **Hardware:** Mac with Apple Silicon (M1, M2, M3, M4 or Pro/Max/Ultra variants).
- **Operating System:** macOS Sonoma (14.0+) or macOS Sequoia (15.0+ recommended for AVX2 support).
- **Development Toolchain:**
  - Xcode 15.0+ or Xcode 16+ with Command Line Tools (`xcode-select --install`).
  - Swift Toolchain 5.10 or Swift 6.0 (`swift --version`).
  - Git (`git --version`).
  - Python 3 (`python3 --version`).

### Clone & Build Locally
```bash
# Clone the repository
git clone https://github.com/NicolasBecasAzagra/MacOSGaming.git
cd MacOSGaming

# Build all modules (MacOSGamingCore, CLI macosgaming, and MacOSGamingApp)
swift build

# Build optimized production release binaries
swift build -c release
```

### Run the App and CLI
```bash
# Run the CLI doctor diagnostics
swift run macosgaming doctor
swift run macosgaming --help

# Launch the native SwiftUI desktop application
swift run MacOSGamingApp
```

---

## 🌿 2. Git Workflow & Branching

1. Always create a clean feature branch from `main`:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b <type>/<descriptive-name>
   ```
2. Recommended branch prefixes:
   - `feat/`: New feature, UI view, or engine functionality.
   - `fix/`: Bug fix or regression repair.
   - `docs/`: Documentation, guides, or compatibility matrix updates.
   - `test/`: New test cases or test harness enhancements.
   - `ci/`: GitHub Actions workflows or build automation scripts.
   - `chore/`: Maintenance, releases, or configuration changes.

---

## 📝 3. Commit Message Conventions (Conventional Commits)

We strictly adhere to the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/) specification:

```
<type>(<optional scope>): <concise description in imperative mood>

[optional body explaining why the change is necessary]

[optional footer with referenced issues, e.g., Closes #12]
```

### Accepted Types:
- `feat`: New capability in CLI, Core, or App.
- `fix`: Bug fix.
- `docs`: Documentation-only updates (`docs/`, `README.md`, etc.).
- `test`: Adding or refactoring unit tests.
- `ci`: Changes to CI/CD workflows (`.github/workflows/`).
- `refactor`: Code changes that neither fix a bug nor add a feature.
- `perf`: Performance improvements in parsing or hardware detection.
- `chore`: Housekeeping, releases, dependency bumps.

*Example:*
```bash
git commit -m "feat(sentinel): add detection for ACE kernel anti-cheat"
```

---

## 🎮 4. Adding or Updating Game Profiles

Game compatibility profiles reside in `data/profiles/<game-id>.json`. Every profile must validate against `data/profiles/schema.json`.

### 4.1 Mandatory Ethical & Legal Principles
- **Zero Anti-Cheat Tampering:** Never implement or document mechanisms to bypass, hook, or tamper with multiplayer anti-cheat software. If a game mandates a Ring-0 kernel driver (e.g., Vanguard, BattlEye kernel), its launch policy must strictly be `"block_kernel_anticheat"`.
- **Zero Piracy:** Do not link to cracked binaries, illegitimate download sources, or unauthorized digital stores.
- **Mandatory Sources:** Every profile must include active URLs that return HTTP 200 from official publishers, verified wikis, or reputable databases.

### 4.2 JSON Profile Schema Example
```json
{
  "id": "my-game",
  "name": "Official Game Title",
  "publisher": "Game Publisher Name",
  "steam_app_id": 123456,
  "compatibility_status": "likely_compatible",
  "confidence_level": "verified",
  "last_verified": "2026-10-09",
  "anti_cheat": {
    "name": "Easy Anti-Cheat",
    "type": "userspace",
    "supported_on_macos": false,
    "offline_mode_allowed": true
  },
  "launch_policy": "allow_offline_only",
  "policy_notice": "Multiplayer requires Windows. Offline single-player mode executes without anti-cheat.",
  "recommended_runtime": {
    "graphics_backend": "dxmt",
    "environment_variables": {
      "ROSETTA_ADVERTISE_AVX": "1",
      "WINEMSYNC": "1"
    }
  },
  "sources": [
    "https://store.steampowered.com/app/123456/...",
    "https://en.wikipedia.org/wiki/..."
  ]
}
```

### 4.3 Profile Local Validation
Before submitting a PR, validate syntax, schema, and live URLs:
```bash
# Validate JSON syntax
plutil -lint data/profiles/my-game.json

# Regenerate compatibility matrix HTML page
python3 scripts/generate_compatibility_page.py

# Validate all profile URLs return HTTP 200
./scripts/validate_sources.sh
```

---

## 🧪 5. Running Tests & Local CI

Run the full automated test suite before opening a Pull Request:

```bash
# Clean temporary AppleDouble files if present
find . -type f -name "._*" -delete

# Run all unit and integration tests
swift test -v

# Run SwiftUI App tests specifically
swift test --filter MacOSGamingAppTests -v

# Verify production release builds
swift build --product MacOSGamingApp -c release
swift build --product macosgaming -c release

# Verify compatibility matrix generator is fresh
python3 scripts/generate_compatibility_page.py --check

# Verify live profile URLs
./scripts/validate_sources.sh
```

---

## 🚀 6. Submitting a Pull Request

1. Push your branch to GitHub:
   ```bash
   git push origin <your-branch>
   ```
2. Open a Pull Request with a clear description:
   - Summary of changes and rationale.
   - Linked GitHub issues or feature requests.
   - Output from `swift test`.
3. All GitHub Actions status checks must pass green before merging.
