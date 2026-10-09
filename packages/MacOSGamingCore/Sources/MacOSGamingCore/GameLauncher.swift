import Foundation

public struct LaunchConfiguration: Sendable {
    public let gameId: String
    public let customExecutablePath: URL?
    public let additionalArguments: [String]
    public let offlineConsent: Bool
    public let isDryRun: Bool
    public let timeoutSeconds: Double?
    public let enableSignalHandling: Bool
    public let autoRetryWithAlternativeConfig: Bool

    public init(
        gameId: String,
        customExecutablePath: URL? = nil,
        additionalArguments: [String] = [],
        offlineConsent: Bool = false,
        isDryRun: Bool = false,
        timeoutSeconds: Double? = nil,
        enableSignalHandling: Bool = false,
        autoRetryWithAlternativeConfig: Bool = false
    ) {
        self.gameId = gameId
        self.customExecutablePath = customExecutablePath
        self.additionalArguments = additionalArguments
        self.offlineConsent = offlineConsent
        self.isDryRun = isDryRun
        self.timeoutSeconds = timeoutSeconds
        self.enableSignalHandling = enableSignalHandling
        self.autoRetryWithAlternativeConfig = autoRetryWithAlternativeConfig
    }
}

public enum LaunchResult: Sendable {
    case blockedBySentinel(profile: GameProfile, reason: String, alternatives: [String])
    case profileNotFound(gameId: String)
    case executableNotFound(gameId: String, searchedPaths: [String], suggestion: String)
    case runtimeMissing(dependencyName: String, instructions: String)
    case launched(
        profile: GameProfile,
        executionResult: ExecutionResult,
        prefixPath: URL,
        retryAttempted: Bool,
        alternativeConfigApplied: String?
    )
}

public struct GameLauncher: Sendable {
    private let profileRepository: GameProfileRepository
    private let sentinel: AntiCheatSentinel
    private let steamDetector: SteamLibraryDetector
    private let prefixManager: PrefixManager
    private let dependencyManager: DependencyManager
    private let processRunner: ProcessRunner

    public init(
        profileRepository: GameProfileRepository = GameProfileRepository(),
        sentinel: AntiCheatSentinel = AntiCheatSentinel(),
        steamDetector: SteamLibraryDetector = SteamLibraryDetector(),
        prefixManager: PrefixManager = PrefixManager(),
        dependencyManager: DependencyManager = DependencyManager(),
        processRunner: ProcessRunner = ProcessRunner()
    ) {
        self.profileRepository = profileRepository
        self.sentinel = sentinel
        self.steamDetector = steamDetector
        self.prefixManager = prefixManager
        self.dependencyManager = dependencyManager
        self.processRunner = processRunner
    }

    public func launch(
        configuration config: LaunchConfiguration,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) -> LaunchResult {
        // 1. Resolve Game Profile
        guard let profile = profileRepository.profile(for: config.gameId) else {
            return .profileNotFound(gameId: config.gameId)
        }

        // 2. Anti-Cheat Sentinel Pre-flight Check (Strict block on kernel anti-cheat)
        let sentinelDecision = sentinel.evaluate(profile: profile, userConsentOffline: config.offlineConsent)
        var mandatoryArgs: [String] = []

        switch sentinelDecision {
        case .blocked(let p, let reason, let alternatives):
            return .blockedBySentinel(profile: p, reason: reason, alternatives: alternatives)

        case .offlineOnly(_, _, let reqArgs, _):
            mandatoryArgs = reqArgs

        case .permitted:
            break
        }

        // 3. Resolve Target Executable
        let targetExecutable: URL
        var searchedPaths: [String] = []

        if let customPath = config.customExecutablePath {
            searchedPaths.append(customPath.path)
            guard config.isDryRun || FileManager.default.fileExists(atPath: customPath.path) else {
                return .executableNotFound(
                    gameId: profile.id,
                    searchedPaths: searchedPaths,
                    suggestion: "The executable file at '\(customPath.path)' does not exist."
                )
            }
            targetExecutable = customPath
        } else {
            // Check Steam Library
            let defaultSteamSearch = steamDetector.steamRootDirectory.appendingPathComponent("steamapps/common").path
            searchedPaths.append(defaultSteamSearch)

            if let steamApp = steamDetector.findApp(forProfileId: profile.id, profileRepository: profileRepository),
               let exe = steamApp.executablePath {
                targetExecutable = exe
            } else if config.isDryRun {
                targetExecutable = URL(fileURLWithPath: "/simulated/steam/\(profile.id).exe")
            } else {
                return .executableNotFound(
                    gameId: profile.id,
                    searchedPaths: searchedPaths,
                    suggestion: "Game not found in Steam Library. Ensure game is installed in Steam or pass '--path /path/to/game.exe'."
                )
            }
        }

        // 4. Create or reuse isolated Wine prefix
        let prefixInfo: PrefixInfo
        do {
            prefixInfo = try prefixManager.createIsolatedPrefix(for: profile.id)
        } catch {
            return .runtimeMissing(
                dependencyName: "Prefix Storage",
                instructions: "Failed to initialize isolated prefix sandbox: \(error.localizedDescription)"
            )
        }

        // 5. Assemble Environment Variables & Command
        var finalEnv = profile.recommendedRuntime.environmentVariables
        finalEnv["WINEPREFIX"] = prefixInfo.prefixDirectory.path
        finalEnv["WINEDEBUG"] = "-all"

        // Auto-configure DXMT overrides if DXMT backend is requested
        if profile.recommendedRuntime.graphicsBackend == .dxmt {
            finalEnv["WINEDLLOVERRIDES"] = "d3d11=n,b;dxgi=n,b"
        }

        // Merge mandatory sentinel arguments (e.g. -nobattleye) with user arguments
        let finalArgs = mandatoryArgs + config.additionalArguments

        // 6. Check for dry run mode
        if config.isDryRun {
            let dryRunLog = """
            [MacOSGaming DRY-RUN SIMULATION]
            Profile: \(profile.name) (\(profile.id))
            Target Executable: \(targetExecutable.path)
            Prefix Sandbox: \(prefixInfo.prefixDirectory.path)
            Configured Environment: \(finalEnv)
            Arguments: \(finalArgs)
            [✓] Dry run validated successfully without spawning process.
            """
            onOutput?(dryRunLog)
            return .launched(
                profile: profile,
                executionResult: ExecutionResult(
                    exitCode: 0,
                    stdoutOutput: dryRunLog,
                    stderrOutput: "",
                    diagnosticMatches: []
                ),
                prefixPath: prefixInfo.prefixDirectory,
                retryAttempted: false,
                alternativeConfigApplied: nil
            )
        }

        // 7. Resolve Runner Binary (Native vs Wine)
        let isNative = profile.compatibilityStatus == .nativeMacOS && targetExecutable.pathExtension.lowercased() != "exe"

        let executableToRun: String
        let argumentsToRun: [String]

        if isNative {
            executableToRun = targetExecutable.path
            argumentsToRun = finalArgs
        } else {
            guard let wineBinary = dependencyManager.resolveWineBinary() else {
                return .runtimeMissing(
                    dependencyName: "Wine-CX Runtime (wine64)",
                    instructions: "Wine-CX was not found on your system. Run 'macosgaming setup' for guided installation instructions."
                )
            }
            executableToRun = wineBinary
            argumentsToRun = [targetExecutable.path] + finalArgs
        }

        // 8. Execute via ProcessRunner
        let firstResult: ExecutionResult
        do {
            firstResult = try processRunner.run(
                executable: executableToRun,
                arguments: argumentsToRun,
                environment: finalEnv,
                workingDirectory: targetExecutable.deletingLastPathComponent(),
                timeoutSeconds: config.timeoutSeconds,
                enableSignalHandling: config.enableSignalHandling,
                onOutput: onOutput
            )
        } catch {
            firstResult = ExecutionResult(
                exitCode: 1,
                stdoutOutput: "",
                stderrOutput: error.localizedDescription,
                diagnosticMatches: []
            )
        }

        // 9. Check if automatic retry with alternative configuration is requested and needed
        if config.autoRetryWithAlternativeConfig && !firstResult.isSuccess {
            let (retryEnv, retryArgs, alternativeSummary) = determineAlternativeConfig(
                profile: profile,
                currentEnv: finalEnv,
                currentArgs: argumentsToRun
            )

            onOutput?("\n[GameLauncher] Primary launch attempt failed (exit code \(firstResult.exitCode)).\n")
            onOutput?("[GameLauncher] Triggering automated retry with alternative configuration:\n")
            onOutput?("  -> \(alternativeSummary)\n\n")

            let retryResult: ExecutionResult
            do {
                retryResult = try processRunner.run(
                    executable: executableToRun,
                    arguments: retryArgs,
                    environment: retryEnv,
                    workingDirectory: targetExecutable.deletingLastPathComponent(),
                    timeoutSeconds: config.timeoutSeconds,
                    enableSignalHandling: config.enableSignalHandling,
                    onOutput: onOutput
                )
            } catch {
                retryResult = ExecutionResult(
                    exitCode: 1,
                    stdoutOutput: "",
                    stderrOutput: error.localizedDescription,
                    diagnosticMatches: []
                )
            }

            return .launched(
                profile: profile,
                executionResult: retryResult,
                prefixPath: prefixInfo.prefixDirectory,
                retryAttempted: true,
                alternativeConfigApplied: alternativeSummary
            )
        }

        return .launched(
            profile: profile,
            executionResult: firstResult,
            prefixPath: prefixInfo.prefixDirectory,
            retryAttempted: false,
            alternativeConfigApplied: nil
        )
    }

    private func determineAlternativeConfig(
        profile: GameProfile,
        currentEnv: [String: String],
        currentArgs: [String]
    ) -> (env: [String: String], args: [String], summary: String) {
        var newEnv = currentEnv
        var newArgs = currentArgs
        var changes: [String] = []

        // If DXMT was used, fallback to standard Wine DXVK / built-in DLLs
        if profile.recommendedRuntime.graphicsBackend == .dxmt {
            newEnv["WINEDLLOVERRIDES"] = "d3d11=b;dxgi=b"
            changes.append("Fallback Direct3D 11 translation from DXMT to Wine/DXVK")
        }

        // If WINEMSYNC was enabled, fallback to standard synchronization
        if currentEnv["WINEMSYNC"] == "1" {
            newEnv["WINEMSYNC"] = "0"
            changes.append("Disabled WINEMSYNC=1 (fallback to server synchronization)")
        }

        // Ensure AVX advertisement is set if running on macOS 15+
        if newEnv["ROSETTA_ADVERTISE_AVX"] != "1" {
            newEnv["ROSETTA_ADVERTISE_AVX"] = "1"
            changes.append("Enabled ROSETTA_ADVERTISE_AVX=1")
        }

        // Add standard compatibility rendering arguments
        if !newArgs.contains("-dx11") {
            newArgs.append("-dx11")
            changes.append("Injected fallback launch flag -dx11")
        }

        let summary = changes.isEmpty ? "Applied safe fallback environment" : changes.joined(separator: ", ")
        return (newEnv, newArgs, summary)
    }
}
