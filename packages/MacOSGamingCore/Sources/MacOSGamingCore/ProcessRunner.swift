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
    public func executeLegalTestRun(
        profile: GameProfile,
        additionalArgs: [String] = [],
        onOutput: (@Sendable (String) -> Void)? = nil
    ) -> ExecutionResult {
        let testScript = """
        echo "=== [MacOSGaming Sandbox Test Runner] ==="
        echo "Profile ID: \(profile.id)"
        echo "Game Name: \(profile.name)"
        echo "ROSETTA_ADVERTISE_AVX=$ROSETTA_ADVERTISE_AVX"
        echo "WINEMSYNC=$WINEMSYNC"
        echo "Execution Mode: Sandboxed Test Harness"
        echo "Simulating DirectX/Metal pipeline handshake: OK"
        echo "Checking anti-cheat status: No kernel anti-cheat active in test sandbox"
        echo "=== Test Harness Completed Successfully ==="
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
