import XCTest
@testable import MacOSGamingCore

final class ProcessRunnerSignalTests: XCTestCase {

    func testProcessTimeoutTerminatesHangingProcess() throws {
        let runner = ProcessRunner()
        let startTime = Date()

        let result = try runner.run(
            executable: "/bin/sleep",
            arguments: ["10"],
            timeoutSeconds: 0.25,
            enableSignalHandling: false
        )

        let duration = Date().timeIntervalSince(startTime)

        XCTAssertTrue(result.wasTerminatedByTimeout, "Process should be marked as terminated by timeout")
        XCTAssertFalse(result.isSuccess, "Timed out process should not be reported as successful")
        XCTAssertLessThan(duration, 3.0, "Watchdog should kill process well before 10 seconds")
        XCTAssertTrue(result.diagnosticMatches.contains { $0.matchedPattern == "Process Timeout" })
    }

    func testProcessNormalExitWithoutTimeout() throws {
        let runner = ProcessRunner()

        let result = try runner.run(
            executable: "/bin/echo",
            arguments: ["Normal termination"],
            timeoutSeconds: 5.0,
            enableSignalHandling: false
        )

        XCTAssertFalse(result.wasTerminatedByTimeout)
        XCTAssertFalse(result.wasTerminatedBySignal)
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(result.stdoutOutput.contains("Normal termination"))
    }

    func testSignalHandlingEnabledExecutesAndCleansUp() throws {
        let runner = ProcessRunner()

        let result = try runner.run(
            executable: "/bin/echo",
            arguments: ["Signal-enabled execution"],
            timeoutSeconds: 5.0,
            enableSignalHandling: true
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertFalse(result.wasTerminatedBySignal)
        XCTAssertTrue(result.stdoutOutput.contains("Signal-enabled execution"))
    }
}
