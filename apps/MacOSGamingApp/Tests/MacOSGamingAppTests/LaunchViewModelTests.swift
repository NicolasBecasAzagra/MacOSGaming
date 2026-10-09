import XCTest
@testable import MacOSGamingApp
@testable import MacOSGamingCore

@MainActor
final class LaunchViewModelTests: XCTestCase {
    func testLaunchViewModelRespectsSentinelForKernelAntiCheat() async throws {
        let repo = GameProfileRepository()
        let launcher = GameLauncher(profileRepository: repo)
        let viewModel = LaunchViewModel(launcher: launcher, profileRepository: repo)

        // Select Valorant (which has Vanguard kernel anti-cheat)
        viewModel.selectGame(gameId: "valorant")
        XCTAssertEqual(viewModel.selectedGameId, "valorant")
        XCTAssertNotNil(viewModel.selectedProfile)
        XCTAssertEqual(viewModel.selectedProfile?.antiCheat.type, .kernelRing0)

        // Attempt launch
        viewModel.launch()

        // Wait for async execution
        let deadline = Date().addingTimeInterval(5.0)
        while viewModel.isLaunching && Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        XCTAssertFalse(viewModel.isLaunching)
        XCTAssertTrue(viewModel.wasBlockedBySentinel)
        XCTAssertEqual(viewModel.exitCode, 2)
        XCTAssertFalse(viewModel.blockReason.isEmpty)
        XCTAssertFalse(viewModel.alternatives.isEmpty)
        XCTAssertTrue(viewModel.logs.contains("Anti-Cheat Sentinel"))
    }

    func testLaunchViewModelDryRunCompletesSuccessfullyForSupportedGame() async throws {
        let repo = GameProfileRepository()
        let launcher = GameLauncher(profileRepository: repo)
        let viewModel = LaunchViewModel(launcher: launcher, profileRepository: repo)

        viewModel.selectGame(gameId: "dota-2")
        viewModel.isDryRun = true

        viewModel.launch()

        let deadline = Date().addingTimeInterval(5.0)
        while viewModel.isLaunching && Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        XCTAssertFalse(viewModel.isLaunching)
        XCTAssertFalse(viewModel.wasBlockedBySentinel)
        XCTAssertEqual(viewModel.exitCode, 0)
        XCTAssertTrue(viewModel.logs.contains("DRY-RUN"))
    }

    func testSelectGameClearsState() {
        let viewModel = LaunchViewModel()
        viewModel.selectGame(gameId: "elden-ring")

        XCTAssertEqual(viewModel.selectedGameId, "elden-ring")
        XCTAssertEqual(viewModel.selectedProfile?.id, "elden-ring")
        XCTAssertFalse(viewModel.wasBlockedBySentinel)
        XCTAssertEqual(viewModel.blockReason, "")
        XCTAssertNil(viewModel.exitCode)
        XCTAssertEqual(viewModel.logs, "")
    }

    func testCancelExecution() {
        let viewModel = LaunchViewModel()
        viewModel.isLaunching = true
        viewModel.cancel()
        XCTAssertFalse(viewModel.isLaunching)
        XCTAssertTrue(viewModel.logs.contains("Cancelación"))
    }
}
