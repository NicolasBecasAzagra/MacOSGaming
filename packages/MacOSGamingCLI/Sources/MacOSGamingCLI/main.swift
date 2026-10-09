import Foundation
import MacOSGamingCore

@main
struct MacOSGamingCLI {
    static func main() {
        let args = CommandLine.arguments

        guard args.count > 1 else {
            printHelp()
            exit(0)
        }

        let command = args[1].lowercased()

        switch command {
        case "doctor":
            let asJSON = args.contains("--json")
            runDoctor(json: asJSON)

        case "list":
            runList()

        case "info":
            guard args.count > 2 else {
                print("Error: Missing game ID. Usage: macosgaming info <game-id>")
                exit(1)
            }
            runInfo(gameId: args[2])

        case "launch":
            guard args.count > 2 else {
                print("Error: Missing game ID. Usage: macosgaming launch <game-id> [--path <path>] [--offline] [--dry-run]")
                exit(1)
            }
            let gameId = args[2]
            var customPath: URL? = nil
            if let pathIdx = args.firstIndex(of: "--path"), pathIdx + 1 < args.count {
                customPath = URL(fileURLWithPath: args[pathIdx + 1])
            }
            let offline = args.contains("--offline")
            let dryRun = args.contains("--dry-run")
            runLaunch(gameId: gameId, customPath: customPath, offline: offline, dryRun: dryRun)

        case "setup":
            runSetup()

        case "steam":
            runSteam()

        case "test-run":
            guard args.count > 2 else {
                print("Error: Missing game ID. Usage: macosgaming test-run <game-id> [--offline]")
                exit(1)
            }
            let offline = args.contains("--offline")
            runTest(gameId: args[2], offline: offline)

        case "--help", "-h", "help":
            printHelp()

        default:
            print("Unknown command: '\(command)'. Run 'macosgaming --help' for available commands.")
            exit(1)
        }
    }

    static func printHelp() {
        print("""
        ===============================================================
                     MacOSGaming CLI — Engine & Diagnostics
        ===============================================================
        Usage: macosgaming <command> [options]

        Commands:
          doctor [--json]         Inspect Mac hardware, Metal GPU, and Rosetta 2 readiness
          list                    List all available game profiles and compatibility status
          info <game-id>          Display verified profile details, anti-cheat, and sources
          steam                   Scan Steam library and list installed games mapped to profiles
          setup                   Inspect dependency runtimes (Wine-CX, DXMT, DXVK) and guide setup
          launch <game-id>        Full launch pipeline: Steam lookup, Wine prefix, profile & exec
                                  (Options: '--path <path>', '--offline', '--dry-run')
          test-run <game-id>      Evaluate sentinel and execute sandboxed legal test harness
                                  (Optional: '--offline' for offline-compatible games)
          help                    Display this help message

        Examples:
          macosgaming doctor
          macosgaming setup
          macosgaming steam
          macosgaming list
          macosgaming info cs2
          macosgaming launch elden-ring --offline
          macosgaming launch gta-v --offline --dry-run
          macosgaming launch valorant
        ===============================================================
        """)
    }

    static func runDoctor(json: Bool) {
        let detector = SystemDetector()
        let report = detector.detect()

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode([
                "chip": report.chipModel,
                "cores": "\(report.cpuCores)",
                "memory_gb": String(format: "%.1f", report.unifiedMemoryGB),
                "gpu": report.gpuName,
                "hardware_ray_tracing": "\(report.supportsHardwareRayTracing)",
                "os_version": report.osVersion,
                "os_major_version": "\(report.osMajorVersion)",
                "os_marketing_name": report.osMarketingName,
                "supports_avx2": "\(report.supportsAVX2)",
                "rosetta_installed": "\(report.isRosettaInstalled)",
                "free_disk_gb": String(format: "%.1f", report.freeDiskSpaceGB),
                "readiness_score": "\(report.readinessScore)"
            ]), let str = String(data: data, encoding: .utf8) {
                print(str)
            }
            return
        }

        let avx2Status = report.supportsAVX2
            ? "Supported (macOS \(report.osMajorVersion) >= 15)"
            : "Unsupported (macOS \(report.osMajorVersion) < 15)"

        print("""
        +-------------------------------------------------------------+
        |                 MACOSGAMING SYSTEM DOCTOR                   |
        +-------------------------------------------------------------+
          Apple Silicon Chip:    \(report.chipModel)
          CPU Core Count:        \(report.cpuCores) cores
          Unified Memory (RAM):  \(String(format: "%.1f GB", report.unifiedMemoryGB))
          Metal GPU:             \(report.gpuName)
          Hardware Ray Tracing:  \(report.supportsHardwareRayTracing ? "Yes (M3/M4+)" : "No (M1/M2 or software only)")
          macOS Version:         macOS \(report.osMarketingName) \(report.osVersion)
          Rosetta 2 AVX2:        \(avx2Status)
          Rosetta 2 Status:      \(report.isRosettaInstalled ? "Installed & Active" : "Not Found (Run: softwareupdate --install-rosetta)")
          Available Disk Space:  \(String(format: "%.1f GB", report.freeDiskSpaceGB))
        +-------------------------------------------------------------+
          GAMING READINESS SCORE: [ \(report.readinessScore) / 100 ]
        +-------------------------------------------------------------+
        """)

        if !report.isRosettaInstalled {
            print("  [!] Action Required: Install Rosetta 2 using:")
            print("      softwareupdate --install-rosetta --agree-to-license\n")
        }
        if !report.supportsAVX2 {
            print("  [*] Note: For modern games requiring AVX/AVX2 instructions,")
            print("      macOS 15.0 or later is required (current: \(report.osVersion)).\n")
        }
    }

    static func runList() {
        let repo = GameProfileRepository()
        let profiles = repo.allProfiles()

        print("+--------------------+------------------------------------------+-----------------------+")
        print("| Game ID            | Compatibility Status                     | Anti-Cheat            |")
        print("+--------------------+------------------------------------------+-----------------------+")
        for p in profiles {
            let idPad = p.id.padding(toLength: 18, withPad: " ", startingAt: 0)
            let statusPad = p.compatibilityStatus.rawValue.padding(toLength: 40, withPad: " ", startingAt: 0)
            let acPad = p.antiCheat.name.padding(toLength: 21, withPad: " ", startingAt: 0)
            print("| \(idPad) | \(statusPad) | \(acPad) |")
        }
        print("+--------------------+------------------------------------------+-----------------------+")
    }

    static func runInfo(gameId: String) {
        let repo = GameProfileRepository()
        guard let p = repo.profile(for: gameId) else {
            print("Profile '\(gameId)' not found. Run 'macosgaming list' to see available profiles.")
            exit(1)
        }

        print("""
        ===============================================================
        GAME PROFILE: \(p.name) (\(p.publisher))
        ===============================================================
        Status:             \(p.compatibilityStatus.displayTitle)
        Confidence Level:   \(p.confidenceLevel.rawValue.uppercased())
        Last Verified:      \(p.lastVerified)
        Anti-Cheat System:  \(p.antiCheat.name) (Type: \(p.antiCheat.type.rawValue))
        macOS Supported:    \(p.antiCheat.supportedOnMacOS ? "Yes" : "No")
        Launch Policy:      \(p.launchPolicy.rawValue)

        Policy Notice:
        \(p.policyNotice)

        Graphics Translator: \(p.recommendedRuntime.graphicsBackend.rawValue)
        Environment Flags:  \(p.recommendedRuntime.environmentVariables)

        Verified Sources:
        """)
        for s in p.sources {
            print("  - \(s)")
        }
        print("===============================================================")
    }

    static func runTest(gameId: String, offline: Bool) {
        let repo = GameProfileRepository()
        guard let profile = repo.profile(for: gameId) else {
            print("Profile '\(gameId)' not found. Run 'macosgaming list'.")
            exit(1)
        }

        let sentinel = AntiCheatSentinel()
        let decision = sentinel.evaluate(profile: profile, userConsentOffline: offline)

        switch decision {
        case .blocked(let p, let reason, let alternatives):
            print("""
            [!] LAUNCH BLOCKED BY ANTI-CHEAT SENTINEL
            Game: \(p.name)
            Reason:
            \(reason)

            Legal & Technical Alternatives:
            """)
            for alt in alternatives {
                print("  -> \(alt)")
            }
            exit(2)

        case .offlineOnly(let p, let notice, let reqArgs, let env):
            print("""
            ================================================================================
                    MACOSGAMING TEST-RUN HARNESS (OFFLINE SANDBOX DRY RUN)
            ================================================================================
            Target Game Profile: \(p.name)
            Offline Policy Notice: \(notice)
            Mandatory Arguments: \(reqArgs)
            Sandbox Environment: \(env)

            [NOTICE] Executing diagnostic test harness ONLY.
                     The actual game binary '\(p.name)' is NOT being launched.
                     Game compatibility cannot be verified without running actual game files.
            ================================================================================
            """)
            executeHarness(profile: p, extraArgs: reqArgs)

        case .permitted(let p, let env, let backend):
            print("""
            ================================================================================
                       MACOSGAMING TEST-RUN HARNESS (SANDBOX DRY RUN)
            ================================================================================
            Target Game Profile: \(p.name)
            Translator Backend:  \(backend.rawValue)
            Sandbox Environment: \(env)

            [NOTICE] Executing diagnostic test harness ONLY.
                     The actual game binary '\(p.name)' is NOT being launched.
                     Game compatibility cannot be verified without running actual game files.
            ================================================================================
            """)
            executeHarness(profile: p, extraArgs: [])
        }
    }

    private static func executeHarness(profile: GameProfile, extraArgs: [String]) {
        let prefixMgr = PrefixManager()
        do {
            let prefixInfo = try prefixMgr.createIsolatedPrefix(for: profile.id)
            print("[Harness] Initialized prefix sandbox at: \(prefixInfo.prefixDirectory.path)")
        } catch {
            print("[!] Warning: Could not create sandbox directory: \(error)")
        }

        print("\nStarting sandboxed legal test harness execution...")
        let runner = ProcessRunner()
        let result = runner.executeLegalTestRun(profile: profile, additionalArgs: extraArgs) { text in
            print(text, terminator: "")
        }

        print("\n[Harness] Execution finished with exit code: \(result.exitCode)")
        if !result.diagnosticMatches.isEmpty {
            print("\nDiagnostic Classifier Findings in harness output:")
            for m in result.diagnosticMatches {
                print("  [\(m.severity.rawValue)] \(m.explanation)")
                print("    Recommendation: \(m.recommendation)")
            }
        } else {
            print("[✓] Diagnostic scan clean: 0 runtime errors detected in harness execution.")
        }
        print("\n[REMINDER] Only the test harness ran. Actual game compatibility for '\(profile.name)' was NOT evaluated.")
    }

    static func runLaunch(gameId: String, customPath: URL?, offline: Bool, dryRun: Bool) {
        let launcher = GameLauncher()
        let config = LaunchConfiguration(
            gameId: gameId,
            customExecutablePath: customPath,
            additionalArguments: [],
            offlineConsent: offline,
            isDryRun: dryRun
        )

        print("""
        ================================================================================
                           MACOSGAMING LAUNCH PIPELINE
        ================================================================================
        Target Profile: \(gameId)
        Mode:           \(dryRun ? "Dry Run (Simulation)" : "Live Execution")
        Offline Mode:   \(offline ? "Requested (Offline Single-Player)" : "Standard")
        Executable:     \(customPath?.path ?? "Auto-detecting via Steam Library...")
        ================================================================================
        """)

        let result = launcher.launch(configuration: config) { text in
            print(text, terminator: "")
        }

        switch result {
        case .blockedBySentinel(let p, let reason, let alternatives):
            print("""
            [!] LAUNCH BLOCKED BY ANTI-CHEAT SENTINEL
            Game: \(p.name)
            Reason:
            \(reason)

            Legal & Technical Alternatives:
            """)
            for alt in alternatives {
                print("  -> \(alt)")
            }
            exit(2)

        case .profileNotFound(let id):
            print("Error: Profile '\(id)' not found. Run 'macosgaming list' to view registered profiles.")
            exit(1)

        case .executableNotFound(let id, let searched, let suggestion):
            print("""
            [!] Executable binary not found for game '\(id)'.
            Searched locations:
            """)
            for s in searched {
                print("  - \(s)")
            }
            print("\nSuggestion: \(suggestion)")
            exit(1)

        case .runtimeMissing(let dep, let instructions):
            print("""
            [!] Missing Dependency: \(dep)
            \(instructions)
            """)
            exit(1)

        case .launched(let p, let execResult, let prefix):
            print("\n================================================================================")
            print("Execution finished with exit code: \(execResult.exitCode)")
            print("Prefix Directory: \(prefix.path)")
            if !execResult.diagnosticMatches.isEmpty {
                print("\nDiagnostic Classifier Findings:")
                for m in execResult.diagnosticMatches {
                    print("  [\(m.severity.rawValue)] \(m.explanation)")
                    print("    Recommendation: \(m.recommendation)")
                }
            } else if execResult.exitCode == 0 {
                print("[✓] Process completed successfully.")
            }
            print("================================================================================")
            if execResult.exitCode != 0 {
                exit(execResult.exitCode)
            }
        }
    }

    static func runSetup() {
        let depMgr = DependencyManager()
        do {
            try depMgr.ensureRuntimeDirectories()
            print("[✓] Initialized runtime storage at: \(depMgr.runtimesDirectory.path)\n")
        } catch {
            print("[!] Warning: Could not create runtimes directory: \(error)\n")
        }

        let deps = depMgr.checkDependencies()

        print("""
        +-----------------------------------------------------------------------------+
        |                  MACOSGAMING DEPENDENCY SETUP & DIAGNOSTIC                  |
        +-----------------------------------------------------------------------------+
        """)

        for d in deps {
            let status = d.isInstalled ? "[INSTALLED]" : "[MISSING]  "
            print("\(status) \(d.name)")
            print("   License: \(d.licenseType)")
            print("   Official Source: \(d.officialSourceURL)")
            if let path = d.installedPath {
                print("   Path: \(path)")
            } else {
                print("   Action Required to Install:")
                for line in d.installationInstructions.components(separatedBy: "\n") {
                    print("     \(line)")
                }
            }
            print("-------------------------------------------------------------------------------")
        }
    }

    static func runSteam() {
        let detector = SteamLibraryDetector()
        let apps = detector.detectInstalledApps()

        print("+--------------------+--------------------------------+----------------------------+")
        print("| Steam App ID       | Installed Game Name            | Mapped Profile ID          |")
        print("+--------------------+--------------------------------+----------------------------+")
        if apps.isEmpty {
            print("| No installed Steam games detected in ~/Library/Application Support/Steam           |")
        } else {
            for app in apps {
                let idPad = "\(app.appId)".padding(toLength: 18, withPad: " ", startingAt: 0)
                let namePad = String(app.name.prefix(30)).padding(toLength: 30, withPad: " ", startingAt: 0)
                let profilePad = (app.profileId ?? "none (unmapped)").padding(toLength: 26, withPad: " ", startingAt: 0)
                print("| \(idPad) | \(namePad) | \(profilePad) |")
            }
        }
        print("+--------------------+--------------------------------+----------------------------+")
    }
}
