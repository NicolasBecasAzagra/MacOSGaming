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

public final class ThreadSafeFlag: @unchecked Sendable {
    private var flag: Bool
    private let lock = NSLock()

    public init(_ initial: Bool = false) {
        self.flag = initial
    }

    public var value: Bool {
        lock.lock()
        defer { lock.unlock() }
        return flag
    }

    public func set(_ val: Bool) {
        lock.lock()
        defer { lock.unlock() }
        flag = val
    }
}

public struct ExecutionResult: Sendable, Equatable {
    public let exitCode: Int32
    public let stdoutOutput: String
    public let stderrOutput: String
    public let diagnosticMatches: [DiagnosticMatch]
    public let wasTerminatedByTimeout: Bool
    public let wasTerminatedBySignal: Bool
    public let executionDurationSeconds: Double

    public var isSuccess: Bool {
        exitCode == 0 && !wasTerminatedByTimeout && !wasTerminatedBySignal
    }

    public init(
        exitCode: Int32,
        stdoutOutput: String,
        stderrOutput: String,
        diagnosticMatches: [DiagnosticMatch],
        wasTerminatedByTimeout: Bool = false,
        wasTerminatedBySignal: Bool = false,
        executionDurationSeconds: Double = 0.0
    ) {
        self.exitCode = exitCode
        self.stdoutOutput = stdoutOutput
        self.stderrOutput = stderrOutput
        self.diagnosticMatches = diagnosticMatches
        self.wasTerminatedByTimeout = wasTerminatedByTimeout
        self.wasTerminatedBySignal = wasTerminatedBySignal
        self.executionDurationSeconds = executionDurationSeconds
    }
}

public struct ProcessRunner: Sendable {
    public init() {}

    public func run(
        executable: String,
        arguments: [String] = [],
        environment: [String: String] = [:],
        workingDirectory: URL? = nil,
        timeoutSeconds: Double? = nil,
        enableSignalHandling: Bool = false,
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

        let timedOutFlag = ThreadSafeFlag(false)
        let signaledFlag = ThreadSafeFlag(false)
        let startTime = Date()

        // 1. Optional Signal Handling for graceful shutdown (SIGINT / SIGTERM)
        var sigintSource: DispatchSourceSignal?
        var sigtermSource: DispatchSourceSignal?

        if enableSignalHandling {
            signal(SIGINT, SIG_IGN)
            signal(SIGTERM, SIG_IGN)

            let intSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: DispatchQueue.global(qos: .userInitiated))
            intSrc.setEventHandler {
                signaledFlag.set(true)
                onOutput?("\n[ProcessRunner] Received SIGINT (Ctrl+C). Terminating process gracefully...\n")
                process.terminate()
                DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                    if process.isRunning {
                        kill(process.processIdentifier, SIGKILL)
                    }
                }
            }
            intSrc.resume()
            sigintSource = intSrc

            let termSrc = DispatchSource.makeSignalSource(signal: SIGTERM, queue: DispatchQueue.global(qos: .userInitiated))
            termSrc.setEventHandler {
                signaledFlag.set(true)
                onOutput?("\n[ProcessRunner] Received SIGTERM. Terminating process gracefully...\n")
                process.terminate()
                DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                    if process.isRunning {
                        kill(process.processIdentifier, SIGKILL)
                    }
                }
            }
            termSrc.resume()
            sigtermSource = termSrc
        }

        // 2. Optional Timeout Watchdog
        var timeoutTimer: DispatchSourceTimer?
        if let timeout = timeoutSeconds, timeout > 0 {
            let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
            timer.schedule(deadline: .now() + timeout)
            timer.setEventHandler {
                timedOutFlag.set(true)
                onOutput?("\n[ProcessRunner] Execution timed out after \(timeout) seconds. Sending termination signal...\n")
                process.terminate()
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                    if process.isRunning {
                        kill(process.processIdentifier, SIGKILL)
                    }
                }
            }
            timer.resume()
            timeoutTimer = timer
        }

        try process.run()
        process.waitUntilExit()

        timeoutTimer?.cancel()
        if enableSignalHandling {
            sigintSource?.cancel()
            sigtermSource?.cancel()
            signal(SIGINT, SIG_DFL)
            signal(SIGTERM, SIG_DFL)
        }

        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        let executionDuration = Date().timeIntervalSince(startTime)
        let stdoutStr = stdoutBuffer.stringValue()
        let stderrStr = stderrBuffer.stringValue()
        let combined = stdoutStr + "\n" + stderrStr

        let classifier = DiagnosticClassifier()
        var matches = classifier.analyze(log: combined)

        if timedOutFlag.value {
            matches.append(
                DiagnosticMatch(
                    category: .generalError,
                    severity: .warning,
                    matchedPattern: "Process Timeout",
                    explanation: "Process exceeded the timeout limit of \(timeoutSeconds ?? 0)s and was terminated.",
                    recommendation: "Check for deadlocks or increase timeout if the game requires longer initial loading."
                )
            )
        }

        if signaledFlag.value {
            matches.append(
                DiagnosticMatch(
                    category: .generalError,
                    severity: .info,
                    matchedPattern: "SIGINT/SIGTERM Interruption",
                    explanation: "Process terminated cleanly upon receiving an external interruption signal (SIGINT/SIGTERM).",
                    recommendation: "Normal user or system cancellation."
                )
            )
        }

        return ExecutionResult(
            exitCode: process.terminationStatus,
            stdoutOutput: stdoutStr,
            stderrOutput: stderrStr,
            diagnosticMatches: matches,
            wasTerminatedByTimeout: timedOutFlag.value,
            wasTerminatedBySignal: signaledFlag.value,
            executionDurationSeconds: executionDuration
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
