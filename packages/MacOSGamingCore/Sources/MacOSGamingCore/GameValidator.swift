import Foundation

public struct GameValidationConfig: Sendable {
    public let gameId: String
    public let customExecutablePath: URL?
    public let additionalArguments: [String]
    public let timeoutSeconds: Double?
    public let autoRetryWithAlternativeConfig: Bool
    public let isDryRun: Bool
    public let outputPath: URL?

    public init(
        gameId: String,
        customExecutablePath: URL? = nil,
        additionalArguments: [String] = [],
        timeoutSeconds: Double? = 15.0,
        autoRetryWithAlternativeConfig: Bool = false,
        isDryRun: Bool = false,
        outputPath: URL? = nil
    ) {
        self.gameId = gameId
        self.customExecutablePath = customExecutablePath
        self.additionalArguments = additionalArguments
        self.timeoutSeconds = timeoutSeconds
        self.autoRetryWithAlternativeConfig = autoRetryWithAlternativeConfig
        self.isDryRun = isDryRun
        self.outputPath = outputPath
    }
}

public struct GameValidationReport: Sendable {
    public let gameId: String
    public let gameName: String
    public let timestampISO8601: String
    public let isDryRun: Bool
    public let executablePathSanitized: String
    public let prefixPathSanitized: String
    public let graphicsBackend: String
    public let configurationUsed: [String: String]
    public let launchArguments: [String]
    public let startupTimeMs: Double
    public let totalExecutionDurationSeconds: Double
    public let exitCode: Int32
    public let wasCleanExit: Bool
    public let wasTerminatedByTimeout: Bool
    public let wasTerminatedBySignal: Bool
    public let estimatedFPS: String
    public let diagnosticMatches: [DiagnosticMatch]
    public let reportMarkdown: String
    public let reportURL: URL
}

public enum GameValidationResult: Sendable {
    case blockedBySentinel(profile: GameProfile, reason: String, alternatives: [String])
    case profileNotFound(gameId: String)
    case executableNotFound(gameId: String, searchedPaths: [String], suggestion: String)
    case runtimeMissing(dependencyName: String, instructions: String)
    case validated(report: GameValidationReport)
}

public final class ThreadSafeTimestamp: @unchecked Sendable {
    private var date: Date?
    private let lock = NSLock()

    public init() {}

    public func markNowIfUnset() {
        lock.lock()
        defer { lock.unlock() }
        if date == nil {
            date = Date()
        }
    }

    public var value: Date? {
        lock.lock()
        defer { lock.unlock() }
        return date
    }
}

public struct GameValidator: Sendable {
    private let launcher: GameLauncher
    private let profileRepository: GameProfileRepository
    private let systemDetector: SystemDetector

    public init(
        launcher: GameLauncher = GameLauncher(),
        profileRepository: GameProfileRepository = GameProfileRepository(),
        systemDetector: SystemDetector = SystemDetector()
    ) {
        self.launcher = launcher
        self.profileRepository = profileRepository
        self.systemDetector = systemDetector
    }

    /// Sanitizes any string to remove personal usernames, absolute home paths, and volume paths.
    public static func sanitize(_ text: String, homeDirectory: String = NSHomeDirectory(), userName: String = NSUserName()) -> String {
        var result = text

        // Replace exact home directory with ~
        if !homeDirectory.isEmpty {
            result = result.replacingOccurrences(of: homeDirectory, with: "~")
        }

        // Replace any lingering /Users/<username> paths with ~
        let userPattern = "/Users/[A-Za-z0-9._-]+"
        if let regex = try? NSRegularExpression(pattern: userPattern) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(location: 0, length: result.utf16.count),
                withTemplate: "~"
            )
        }

        // Replace username if leaked standalone
        if !userName.isEmpty && userName != "root" {
            result = result.replacingOccurrences(of: userName, with: "<USER>")
        }

        // Replace /Volumes/<volumeName> with <EXTERNAL_STORAGE>
        let volPattern = "/Volumes/[^/\\s]+"
        if let regex = try? NSRegularExpression(pattern: volPattern) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(location: 0, length: result.utf16.count),
                withTemplate: "<EXTERNAL_STORAGE>"
            )
        }

        return result
    }

    public func validate(
        config: GameValidationConfig,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) -> GameValidationResult {
        // Resolve profile
        guard profileRepository.profile(for: config.gameId) != nil else {
            return .profileNotFound(gameId: config.gameId)
        }

        let sysReport = systemDetector.detect()

        let launchConfig = LaunchConfiguration(
            gameId: config.gameId,
            customExecutablePath: config.customExecutablePath,
            additionalArguments: config.additionalArguments,
            offlineConsent: true,
            isDryRun: config.isDryRun,
            timeoutSeconds: config.timeoutSeconds,
            enableSignalHandling: true,
            autoRetryWithAlternativeConfig: config.autoRetryWithAlternativeConfig
        )

        let startTime = Date()
        let timestampTracker = ThreadSafeTimestamp()

        let outputHook: @Sendable (String) -> Void = { chunk in
            timestampTracker.markNowIfUnset()
            onOutput?(chunk)
        }

        let launchResult = launcher.launch(configuration: launchConfig, onOutput: outputHook)

        switch launchResult {
        case .blockedBySentinel(let p, let reason, let alternatives):
            return .blockedBySentinel(profile: p, reason: reason, alternatives: alternatives)

        case .profileNotFound(let id):
            return .profileNotFound(gameId: id)

        case .executableNotFound(let id, let paths, let suggestion):
            return .executableNotFound(gameId: id, searchedPaths: paths, suggestion: suggestion)

        case .runtimeMissing(let dep, let instructions):
            return .runtimeMissing(dependencyName: dep, instructions: instructions)

        case .launched(let p, let execResult, let prefixPath, let retryAttempted, let altConfig):
            let totalDuration = Date().timeIntervalSince(startTime)
            let startupMs: Double
            if let firstOut = timestampTracker.value {
                startupMs = max(1.0, firstOut.timeIntervalSince(startTime) * 1000.0)
            } else {
                startupMs = max(1.0, execResult.executionDurationSeconds * 1000.0)
            }

            // Estimate FPS
            let estimatedFPS = calculateEstimatedFPS(
                profile: p,
                sysReport: sysReport,
                execResult: execResult
            )

            // Sanitize paths
            let sanitizedPrefix = Self.sanitize(prefixPath.path)
            let sanitizedExecutable = Self.sanitize(config.customExecutablePath?.path ?? "steamapps/common/\(p.id)")

            // Format markdown report
            let isoDateFormatter = ISO8601DateFormatter()
            let dateStr = isoDateFormatter.string(from: Date())

            let markdown = generateMarkdownReport(
                profile: p,
                sysReport: sysReport,
                dateStr: dateStr,
                sanitizedExecutable: sanitizedExecutable,
                sanitizedPrefix: sanitizedPrefix,
                config: config,
                execResult: execResult,
                startupMs: startupMs,
                totalDuration: totalDuration,
                estimatedFPS: estimatedFPS,
                retryAttempted: retryAttempted,
                altConfig: altConfig
            )

            // Resolve output report path
            let reportURL: URL
            if let out = config.outputPath {
                reportURL = out
            } else {
                let defaultReportsDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent("docs/validation")
                try? FileManager.default.createDirectory(at: defaultReportsDir, withIntermediateDirectories: true)
                reportURL = defaultReportsDir.appendingPathComponent("\(p.id)-report.md")
            }

            try? markdown.write(to: reportURL, atomically: true, encoding: .utf8)

            let report = GameValidationReport(
                gameId: p.id,
                gameName: p.name,
                timestampISO8601: dateStr,
                isDryRun: config.isDryRun,
                executablePathSanitized: sanitizedExecutable,
                prefixPathSanitized: sanitizedPrefix,
                graphicsBackend: p.recommendedRuntime.graphicsBackend.rawValue,
                configurationUsed: p.recommendedRuntime.environmentVariables,
                launchArguments: config.additionalArguments,
                startupTimeMs: startupMs,
                totalExecutionDurationSeconds: totalDuration,
                exitCode: execResult.exitCode,
                wasCleanExit: execResult.isSuccess,
                wasTerminatedByTimeout: execResult.wasTerminatedByTimeout,
                wasTerminatedBySignal: execResult.wasTerminatedBySignal,
                estimatedFPS: estimatedFPS,
                diagnosticMatches: execResult.diagnosticMatches,
                reportMarkdown: markdown,
                reportURL: reportURL
            )

            return .validated(report: report)
        }
    }

    private func calculateEstimatedFPS(
        profile: GameProfile,
        sysReport: SystemReport,
        execResult: ExecutionResult
    ) -> String {
        // 1. Check if output stream contains explicit framerate or HUD benchmark metrics
        let combinedLog = execResult.stdoutOutput + "\n" + execResult.stderrOutput
        if let match = parseFramerateFromLog(combinedLog) {
            return "\(match) (Measured via Engine Log)"
        }

        // 2. Hardware-assisted Metal estimation baseline
        let chip = sysReport.chipModel.lowercased()
        let isNative = profile.compatibilityStatus == .nativeMacOS

        if isNative {
            if chip.contains("max") || chip.contains("ultra") {
                return "120 - 144+ FPS @ 1440p (Native Metal Apple Silicon Pipeline)"
            } else if chip.contains("pro") {
                return "90 - 120 FPS @ 1080p/1440p (Native Metal Apple Silicon Pipeline)"
            } else {
                return "60 - 90 FPS @ 1080p (Native Metal Apple Silicon Pipeline)"
            }
        }

        // Translation layer (DXMT / DXVK)
        if profile.recommendedRuntime.graphicsBackend == .dxmt {
            if chip.contains("max") || chip.contains("ultra") {
                return "75 - 100 FPS @ 1440p (Estimated via DXMT Direct3D 11 -> Metal)"
            } else if chip.contains("pro") {
                return "60 - 75 FPS @ 1080p (Estimated via DXMT Direct3D 11 -> Metal)"
            } else {
                return "45 - 60 FPS @ 1080p (Estimated via DXMT Direct3D 11 -> Metal)"
            }
        }

        return "40 - 60 FPS @ 1080p (Estimated via Translation Layer)"
    }

    private func parseFramerateFromLog(_ log: String) -> String? {
        let patterns = [
            "FPS:\\s*([0-9.]+)",
            "Framerate:\\s*([0-9.]+)",
            "\\[DXMT\\]\\s*FPS:\\s*([0-9.]+)",
            "\\[Metal\\]\\s*FPS:\\s*([0-9.]+)"
        ]
        for pat in patterns {
            if let regex = try? NSRegularExpression(pattern: pat, options: .caseInsensitive),
               let match = regex.firstMatch(in: log, range: NSRange(location: 0, length: log.utf16.count)),
               let range = Range(match.range(at: 1), in: log) {
                return "\(log[range]) FPS"
            }
        }
        return nil
    }

    private func generateMarkdownReport(
        profile: GameProfile,
        sysReport: SystemReport,
        dateStr: String,
        sanitizedExecutable: String,
        sanitizedPrefix: String,
        config: GameValidationConfig,
        execResult: ExecutionResult,
        startupMs: Double,
        totalDuration: Double,
        estimatedFPS: String,
        retryAttempted: Bool,
        altConfig: String?
    ) -> String {
        let statusString = execResult.isSuccess ? "PASSED (Clean Exit)" : (execResult.wasTerminatedByTimeout ? "TIMED OUT" : "FAILED (Exit Code \(execResult.exitCode))")

        var md = """
        # Validation Report: \(profile.name) (\(profile.id))

        - **Validation Date:** \(dateStr)
        - **Status:** \(statusString)
        - **Validation Mode:** \(config.isDryRun ? "Dry Run (Simulation)" : "Live Process Execution")

        ---

        ## 1. System Environment
        - **Hardware:** Apple Silicon (\(sysReport.chipModel))
        - **CPU Cores:** \(sysReport.cpuCores)
        - **Unified Memory:** \(String(format: "%.1f GB", sysReport.unifiedMemoryGB))
        - **Metal GPU:** \(sysReport.gpuName)
        - **Hardware Ray Tracing:** \(sysReport.supportsHardwareRayTracing ? "Yes" : "No")
        - **macOS Version:** macOS \(sysReport.osMarketingName) \(sysReport.osVersion)
        - **Rosetta 2 AVX2:** \(sysReport.supportsAVX2 ? "Supported (macOS >= 15)" : "Unsupported")
        - **Gaming Readiness Score:** \(sysReport.readinessScore) / 100

        ---

        ## 2. Launch & Runtime Configuration
        - **Target Executable:** `\(sanitizedExecutable)`
        - **Prefix Sandbox Directory:** `\(sanitizedPrefix)`
        - **Compatibility Tier:** \(profile.compatibilityStatus.rawValue)
        - **Graphics Backend:** \(profile.recommendedRuntime.graphicsBackend.rawValue)
        - **Offline Enforcement:** \(profile.antiCheat.offlineModeAllowed ? "Offline-Mode Safe" : "Standard")
        - **Configured Environment:**
        """

        for (k, v) in profile.recommendedRuntime.environmentVariables.sorted(by: { $0.key < $1.key }) {
            md += "\n  - `\(k)`: `\(v)`"
        }

        if retryAttempted, let alt = altConfig {
            md += "\n- **Automated Fallback Retry:** Applied (`\(alt)`)"
        }

        md += """


        ---

        ## 3. Performance & Stability Metrics
        - **Startup Initialization Time:** \(String(format: "%.1f ms", startupMs))
        - **Total Execution Duration:** \(String(format: "%.2f s", totalDuration))
        - **Exit Code:** `\(execResult.exitCode)`
        - **Terminated by Timeout:** \(execResult.wasTerminatedByTimeout ? "Yes" : "No")
        - **Terminated by Signal:** \(execResult.wasTerminatedBySignal ? "Yes" : "No")
        - **Performance / Framerate:** \(estimatedFPS)
        - **Stability Assessment:** \(execResult.isSuccess ? "Stable execution without crashes or fatal errors" : "Execution halted with non-zero exit code or timeout")

        ---

        ## 4. Diagnostics & Error Analysis
        """

        if execResult.diagnosticMatches.isEmpty {
            md += "\n- **Diagnostic Findings:** No known errors, missing DLLs, or crashes detected.\n"
        } else {
            md += "\n\n| Severity | Category | Diagnostic Explanation | Recommendation |"
            md += "\n|---|---|---|---|"
            for m in execResult.diagnosticMatches {
                md += "\n| \(m.severity.rawValue) | \(m.category) | \(m.explanation) | \(m.recommendation) |"
            }
            md += "\n"
        }

        md += """

        ---

        ## 5. Sanitized Log Output Summary
        ```
        \(Self.sanitize(String(execResult.stdoutOutput.suffix(2000))))
        ```

        *Report automatically generated by MacOSGaming CLI Validation Engine.*
        """

        return md
    }
}
