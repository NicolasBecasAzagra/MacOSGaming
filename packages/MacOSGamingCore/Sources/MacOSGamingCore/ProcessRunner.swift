import Foundation

public final class ThreadSafeBuffer: @unchecked Sendable {
    private var data = Data()
    private let lock = NSLock()

    public init() {}

    public func append(_ chunk: Data) {
        lock.lock()
        defer { lock.unlock() }
        data.append(chunk)
    }

    public func stringValue() -> String {
        lock.lock()
        defer { lock.unlock() }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

public struct ExecutionResult: Sendable, Equatable {
    public let exitCode: Int32
    public let stdoutOutput: String
    public let stderrOutput: String
    public let diagnosticMatches: [DiagnosticMatch]

    public var isSuccess: Bool {
        exitCode == 0
    }

    public init(exitCode: Int32, stdoutOutput: String, stderrOutput: String, diagnosticMatches: [DiagnosticMatch]) {
        self.exitCode = exitCode
        self.stdoutOutput = stdoutOutput
        self.stderrOutput = stderrOutput
        self.diagnosticMatches = diagnosticMatches
    }
}

public struct ProcessRunner: Sendable {
    public init() {}

    public func run(
        executable: String,
        arguments: [String] = [],
        environment: [String: String] = [:],
        workingDirectory: URL? = nil,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) throws -> ExecutionResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        var mergedEnv = ProcessInfo.processInfo.environment
        for (k, v) in environment {
            mergedEnv[k] = v
        }
        process.environment = mergedEnv

        if let wd = workingDirectory {
            process.currentDirectoryURL = wd
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let stdoutBuffer = ThreadSafeBuffer()
        let stderrBuffer = ThreadSafeBuffer()

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            stdoutBuffer.append(chunk)
            if let text = String(data: chunk, encoding: .utf8) {
                onOutput?(text)
            }
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            stderrBuffer.append(chunk)
            if let text = String(data: chunk, encoding: .utf8) {
                onOutput?(text)
            }
        }

        try process.run()
        process.waitUntilExit()

        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        let stdoutStr = stdoutBuffer.stringValue()
        let stderrStr = stderrBuffer.stringValue()
        let combined = stdoutStr + "\n" + stderrStr

        let classifier = DiagnosticClassifier()
        let matches = classifier.analyze(log: combined)

        return ExecutionResult(
            exitCode: process.terminationStatus,
            stdoutOutput: stdoutStr,
            stderrOutput: stderrStr,
            diagnosticMatches: matches
        )
    }

    /// Executes a completely legal, self-contained test run to verify the runner, environment injection, and log parsing.
    /// Explicitly clarifies that this executes a synthetic test harness, NOT the actual game, and does not assert game compatibility.
    public func executeLegalTestRun(
        profile: GameProfile,
        additionalArgs: [String] = [],
        onOutput: (@Sendable (String) -> Void)? = nil
    ) -> ExecutionResult {
        let testScript = """
        echo "================================================================"
        echo "       [MACOSGAMING SANDBOX TEST HARNESS: DRY RUN EXECUTION]    "
        echo "================================================================"
        echo " TARGET PROFILE: \(profile.name) (\(profile.id))"
        echo " HARNESS TYPE: Synthetic Environment & Diagnostic Harness"
        echo " STATUS: Executing test harness ONLY — NOT the actual game"
        echo " GAME RUNTIME COMPATIBILITY: UNVERIFIED (game was not run)"
        echo "----------------------------------------------------------------"
        echo " Environment Check: ROSETTA_ADVERTISE_AVX=$ROSETTA_ADVERTISE_AVX"
        echo " Environment Check: WINEMSYNC=$WINEMSYNC"
        echo " Environment Check: MACOSGAMING_TEST_HARNESS=$MACOSGAMING_TEST_HARNESS"
        echo " Pipeline Diagnostics: Harness simulation completed successfully."
        echo "================================================================"
        """

        var env = profile.recommendedRuntime.environmentVariables
        env["MACOSGAMING_TEST_HARNESS"] = "1"

        do {
            return try run(
                executable: "/bin/sh",
                arguments: ["-c", testScript + " " + additionalArgs.joined(separator: " ")],
                environment: env,
                onOutput: onOutput
            )
        } catch {
            return ExecutionResult(
                exitCode: 1,
                stdoutOutput: "",
                stderrOutput: error.localizedDescription,
                diagnosticMatches: []
            )
        }
    }
}
