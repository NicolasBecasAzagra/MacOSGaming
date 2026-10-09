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
          test-run <game-id>      Evaluate sentinel and execute sandboxed legal test runner
                                  (Optional: '--offline' for offline-compatible games)
          help                    Display this help message

        Examples:
          macosgaming doctor
          macosgaming info valorant
          macosgaming info cs2
          macosgaming test-run elden-ring --offline
          macosgaming test-run valorant
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
                "is_sequoia_or_later": "\(report.isSequoiaOrLater)",
                "rosetta_installed": "\(report.isRosettaInstalled)",
                "free_disk_gb": String(format: "%.1f", report.freeDiskSpaceGB),
                "readiness_score": "\(report.readinessScore)"
            ]), let str = String(data: data, encoding: .utf8) {
                print(str)
            }
            return
        }

        print("""
        +-------------------------------------------------------------+
        |                 MACOSGAMING SYSTEM DOCTOR                   |
        +-------------------------------------------------------------+
          Apple Silicon Chip:    \(report.chipModel)
          CPU Core Count:        \(report.cpuCores) cores
          Unified Memory (RAM):  \(String(format: "%.1f GB", report.unifiedMemoryGB))
          Metal GPU:             \(report.gpuName)
          Hardware Ray Tracing:  \(report.supportsHardwareRayTracing ? "Yes (M3/M4)" : "No (M1/M2 or software only)")
          macOS Version:         \(report.osVersion) (\(report.isSequoiaOrLater ? "Sequoia 15+ [AVX2 Supported]" : "Pre-Sequoia [No AVX2]"))
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
        if !report.isSequoiaOrLater {
            print("  [*] Note: For modern games requiring AVX/AVX2 instructions,")
            print("      macOS Sequoia 15.0 or later is recommended.\n")
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
            print("[*] NOTICE: \(notice)")
            print("    Mandatory Arguments: \(reqArgs)")
            print("    Environment: \(env)")
            executeHarness(profile: p, extraArgs: reqArgs)

        case .permitted(let p, let env, let backend):
            print("[✓] LAUNCH PERMITTED: \(p.name)")
            print("    Translator Backend: \(backend.rawValue)")
            print("    Environment: \(env)")
            executeHarness(profile: p, extraArgs: [])
        }
    }

    private static func executeHarness(profile: GameProfile, extraArgs: [String]) {
        let prefixMgr = PrefixManager()
        do {
            let prefixInfo = try prefixMgr.createIsolatedPrefix(for: profile.id)
            print("[✓] Initialized prefix sandbox at: \(prefixInfo.prefixDirectory.path)")
        } catch {
            print("[!] Warning: Could not create sandbox directory: \(error)")
        }

        print("\nStarting sandboxed legal test harness execution...")
        let runner = ProcessRunner()
        let result = runner.executeLegalTestRun(profile: profile, additionalArgs: extraArgs) { text in
            print(text, terminator: "")
        }

        print("\nExecution finished with exit code: \(result.exitCode)")
        if !result.diagnosticMatches.isEmpty {
            print("\nDiagnostic Classifier Findings:")
            for m in result.diagnosticMatches {
                print("  [\(m.severity.rawValue)] \(m.explanation)")
                print("    Recommendation: \(m.recommendation)")
            }
        } else {
            print("[✓] Diagnostic scan clean: 0 runtime errors detected.")
        }
    }
}
