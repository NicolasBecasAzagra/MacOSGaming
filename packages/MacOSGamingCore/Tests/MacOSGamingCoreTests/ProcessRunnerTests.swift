import XCTest
@testable import MacOSGamingCore

final class ProcessRunnerTests: XCTestCase {
    func testExecuteLegalTestRunClarifiesHarnessAndDoesNotClaimGameCompatibility() {
        let repo = GameProfileRepository()
        guard let profile = repo.profile(for: "elden-ring") else {
            XCTFail("Expected elden-ring profile to exist")
            return
        }

        let runner = ProcessRunner()
        let result = runner.executeLegalTestRun(profile: profile)

        XCTAssertTrue(result.isSuccess, "Test harness execution should exit 0")
        let output = result.stdoutOutput

        // 1. Must clarify it is executing a test harness, NOT the real game
        XCTAssertTrue(output.contains("MACOSGAMING SANDBOX TEST HARNESS"), "Must identify as sandbox test harness")
        XCTAssertTrue(output.contains("NOT the actual game"), "Must explicitly declare NOT the actual game")

        // 2. Must not claim the game was verified compatible
        XCTAssertTrue(
            output.contains("GAME RUNTIME COMPATIBILITY: UNVERIFIED (game was not run)"),
            "Must state game compatibility is unverified because game was not run"
        )
        XCTAssertFalse(
            output.contains("Game Verified Compatible"),
            "Must not claim game compatibility"
        )
    }
}
