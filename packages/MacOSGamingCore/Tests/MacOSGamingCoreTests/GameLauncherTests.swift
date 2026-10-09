import XCTest
@testable import MacOSGamingCore

final class GameLauncherTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let temp = tempDirectory {
            try? FileManager.default.removeItem(at: temp)
        }
        super.tearDown()
    }

    func testSentinelBlocksKernelAntiCheatBeforeExecution() {
        let launcher = GameLauncher()

        // 1. Valorant (Vanguard kernel driver) must be strictly blocked
        let valorantConfig = LaunchConfiguration(gameId: "valorant")
        let valorantResult = launcher.launch(configuration: valorantConfig)

        switch valorantResult {
        case .blockedBySentinel(let profile, let reason, let alternatives):
            XCTAssertEqual(profile.id, "valorant")
            XCTAssertTrue(reason.contains("kernel-level anti-cheat"))
            XCTAssertFalse(alternatives.isEmpty, "Must provide legal alternatives")
        default:
            XCTFail("Valorant must be blocked by sentinel, got: \(valorantResult)")
        }

        // 2. Fortnite (BattlEye/EAC kernel driver) must be strictly blocked
        let fortniteConfig = LaunchConfiguration(gameId: "fortnite")
        let fortniteResult = launcher.launch(configuration: fortniteConfig)

        switch fortniteResult {
        case .blockedBySentinel(let profile, _, let alternatives):
            XCTAssertEqual(profile.id, "fortnite")
            XCTAssertFalse(alternatives.isEmpty)
        default:
            XCTFail("Fortnite must be blocked by sentinel, got: \(fortniteResult)")
        }
    }

    func testDryRunLaunchMode() {
        let launcher = GameLauncher()
        let config = LaunchConfiguration(
            gameId: "elden-ring",
            customExecutablePath: URL(fileURLWithPath: "/dummy/path/eldenring.exe"),
            offlineConsent: true,
            isDryRun: true
        )

        let result = launcher.launch(configuration: config)

        switch result {
        case .launched(let profile, let execResult, let prefix):
            XCTAssertEqual(profile.id, "elden-ring")
            XCTAssertEqual(execResult.exitCode, 0)
            XCTAssertTrue(execResult.stdoutOutput.contains("DRY-RUN SIMULATION"))
            XCTAssertTrue(FileManager.default.fileExists(atPath: prefix.path), "Prefix directory should be created")
        default:
            XCTFail("Dry run should report .launched with simulation results, got: \(result)")
        }
    }

    func testLaunchFlowWithLegalTestBinary() throws {
        let fm = FileManager.default

        // Create a self-contained, DRM-free legal test executable script
        let mockExecutableURL = tempDirectory.appendingPathComponent("legal_test_binary.sh")
        let mockScript = """
        #!/bin/sh
        echo "=== MOCK LEGAL GAME ENGINE STARTED ==="
        echo "Arguments passed: $@"
        echo "WINEPREFIX=$WINEPREFIX"
        echo "ROSETTA_ADVERTISE_AVX=$ROSETTA_ADVERTISE_AVX"
        echo "WINEMSYNC=$WINEMSYNC"
        echo "=== MOCK LEGAL GAME ENGINE EXITING CLEANLY ==="
        exit 0
        """
        try mockScript.write(to: mockExecutableURL, atomically: true, encoding: .utf8)

        // Make executable (chmod +x)
        let permissions = [FileAttributeKey.posixPermissions: 0o755]
        try fm.setAttributes(permissions, ofItemAtPath: mockExecutableURL.path)

        // Launch using native game profile (e.g. native dota-2 or custom native)
        let launcher = GameLauncher()
        let config = LaunchConfiguration(
            gameId: "dota-2",
            customExecutablePath: mockExecutableURL,
            additionalArguments: ["--test-flag", "1"]
        )

        let result = launcher.launch(configuration: config)

        switch result {
        case .launched(let profile, let execResult, let prefix):
            XCTAssertEqual(profile.id, "dota-2")
            XCTAssertEqual(execResult.exitCode, 0, "Execution of test binary should succeed with code 0")
            XCTAssertTrue(execResult.stdoutOutput.contains("MOCK LEGAL GAME ENGINE STARTED"))
            XCTAssertTrue(execResult.stdoutOutput.contains("--test-flag 1"))
            XCTAssertTrue(FileManager.default.fileExists(atPath: prefix.path))
        default:
            XCTFail("Expected .launched, got: \(result)")
        }
    }
}
