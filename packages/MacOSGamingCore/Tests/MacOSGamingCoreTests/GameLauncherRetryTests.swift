import XCTest
@testable import MacOSGamingCore

final class GameLauncherRetryTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let dir = tempDirectory, FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.removeItem(at: dir)
        }
        try super.tearDownWithError()
    }

    func testAutoRetryWithAlternativeConfigExecutesFallback() throws {
        let fm = FileManager.default
        let scriptURL = tempDirectory.appendingPathComponent("conditional_fallback_binary.sh")

        // Script fails (exit 1) unless -dx11 is passed in the arguments
        let script = """
        #!/bin/sh
        for arg in "$@"; do
            if [ "$arg" = "-dx11" ]; then
                echo "Fallback DirectX 11 backend succeeded!"
                exit 0
            fi
        done
        echo "Primary graphics backend initialization failed."
        exit 1
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let launcher = GameLauncher()
        let config = LaunchConfiguration(
            gameId: "dota-2",
            customExecutablePath: scriptURL,
            autoRetryWithAlternativeConfig: true
        )

        var streamedLogs = ""
        let result = launcher.launch(configuration: config) { text in
            streamedLogs += text
        }

        switch result {
        case .launched(let profile, let execResult, _, let retryAttempted, let alternativeConfigApplied):
            XCTAssertEqual(profile.id, "dota-2")
            XCTAssertTrue(retryAttempted, "Automatic retry should have been attempted")
            XCTAssertNotNil(alternativeConfigApplied, "Alternative config summary should be recorded")
            XCTAssertEqual(execResult.exitCode, 0, "Second attempt with -dx11 fallback should succeed")
            XCTAssertTrue(execResult.stdoutOutput.contains("Fallback DirectX 11 backend succeeded!"))
            XCTAssertTrue(streamedLogs.contains("Primary launch attempt failed"))
            XCTAssertTrue(streamedLogs.contains("Triggering automated retry"))
        default:
            XCTFail("Expected .launched result with retry, got: \(result)")
        }
    }

    func testNoRetryWhenDisabledReturnsInitialFailure() throws {
        let fm = FileManager.default
        let scriptURL = tempDirectory.appendingPathComponent("always_failing_binary.sh")

        let script = """
        #!/bin/sh
        echo "Fatal crash in primary pipeline."
        exit 42
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let launcher = GameLauncher()
        let config = LaunchConfiguration(
            gameId: "dota-2",
            customExecutablePath: scriptURL,
            autoRetryWithAlternativeConfig: false
        )

        let result = launcher.launch(configuration: config)

        switch result {
        case .launched(_, let execResult, _, let retryAttempted, let alternativeConfigApplied):
            XCTAssertFalse(retryAttempted, "Retry should not be triggered when disabled")
            XCTAssertNil(alternativeConfigApplied)
            XCTAssertEqual(execResult.exitCode, 42)
            XCTAssertTrue(execResult.stdoutOutput.contains("Fatal crash in primary pipeline"))
        default:
            XCTFail("Expected .launched result, got: \(result)")
        }
    }
}
