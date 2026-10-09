import XCTest
@testable import MacOSGamingCore

final class GameValidatorTests: XCTestCase {
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

    func testGameValidatorSanitizationFunction() {
        let home = NSHomeDirectory()
        let user = NSUserName()

        let rawString = "Crash dump at \(home)/Library/Logs/game.log on /Volumes/PortableSSD/Games by user \(user)"
        let sanitized = GameValidator.sanitize(rawString)

        XCTAssertFalse(sanitized.contains(home), "Sanitized string must not contain absolute home directory")
        XCTAssertFalse(sanitized.contains("/Users/\(user)"), "Sanitized string must not contain /Users/<username>")
        XCTAssertFalse(sanitized.contains("/Volumes/PortableSSD"), "Sanitized string must not contain /Volumes/...")
        XCTAssertTrue(sanitized.contains("~/Library/Logs/game.log"), "Should normalize home directory to ~")
        XCTAssertTrue(sanitized.contains("<EXTERNAL_STORAGE>"), "Should normalize volume path to <EXTERNAL_STORAGE>")
    }

    func testGameValidatorWithLegalTestBinary() throws {
        let fm = FileManager.default
        let testScriptURL = tempDirectory.appendingPathComponent("legal_game_validation.sh")
        let script = """
        #!/bin/sh
        echo "[Engine] Initializing graphics subsystem..."
        echo "[Metal] FPS: 74.5"
        echo "[Engine] Benchmark completed successfully."
        exit 0
        """
        try script.write(to: testScriptURL, atomically: true, encoding: .utf8)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: testScriptURL.path)

        let reportOutputURL = tempDirectory.appendingPathComponent("dota-2-report.md")

        let validator = GameValidator()
        let config = GameValidationConfig(
            gameId: "dota-2",
            customExecutablePath: testScriptURL,
            timeoutSeconds: 5.0,
            outputPath: reportOutputURL
        )

        let result = validator.validate(config: config)

        switch result {
        case .validated(let report):
            XCTAssertEqual(report.gameId, "dota-2")
            XCTAssertEqual(report.exitCode, 0)
            XCTAssertTrue(report.wasCleanExit)
            XCTAssertFalse(report.wasTerminatedByTimeout)
            XCTAssertTrue(report.startupTimeMs > 0.0)
            XCTAssertTrue(report.estimatedFPS.contains("74.5 FPS"), "Should parse framerate from engine log")
            XCTAssertTrue(fm.fileExists(atPath: reportOutputURL.path), "Markdown report file should be written")

            // Critical privacy test: Ensure no absolute user paths or real usernames leak into generated markdown
            let markdown = try String(contentsOf: reportOutputURL, encoding: .utf8)
            XCTAssertFalse(markdown.contains("/Users/" + NSUserName()), "Generated report must not contain /Users/<username>")
            XCTAssertTrue(markdown.contains("# Validation Report: Dota 2 (dota-2)"))
            XCTAssertTrue(markdown.contains("System Environment"))
            XCTAssertTrue(markdown.contains("Performance & Stability Metrics"))

        default:
            XCTFail("Expected .validated result, got: \(result)")
        }
    }

    func testGameValidatorBlocksKernelAntiCheatSentinel() {
        let validator = GameValidator()
        let config = GameValidationConfig(gameId: "valorant")

        let result = validator.validate(config: config)

        switch result {
        case .blockedBySentinel(let profile, let reason, let alternatives):
            XCTAssertEqual(profile.id, "valorant")
            XCTAssertTrue(reason.contains("Vanguard"))
            XCTAssertFalse(alternatives.isEmpty)
        default:
            XCTFail("GameValidator should block Valorant via AntiCheatSentinel, got: \(result)")
        }
    }
}
