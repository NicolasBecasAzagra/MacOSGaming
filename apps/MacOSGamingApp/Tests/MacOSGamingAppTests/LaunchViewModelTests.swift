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
        XCTAssertTrue(viewModel.logs.contains("Cancellation"))
    }

    func testLaunchViewModelPresentsDependencySheetBeforeLaunch() {
        let repo = GameProfileRepository()
        let launcher = GameLauncher(profileRepository: repo)
        let tempPrefixDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let prefixManager = PrefixManager(basePrefixDirectory: tempPrefixDir)
        let viewModel = LaunchViewModel(launcher: launcher, profileRepository: repo, prefixManager: prefixManager)

        viewModel.selectGame(gameId: "elden-ring")
        viewModel.offlineConsent = true
        viewModel.isDryRun = false

        viewModel.launch()

        XCTAssertTrue(viewModel.showDependencySheet, "Dependency resolution modal must be presented when runtimes are missing")
        XCTAssertFalse(viewModel.missingDependencies.isEmpty, "Missing dependencies must be enumerated")
        XCTAssertGreaterThan(viewModel.totalSelectedSizeMB, 0.0, "Total size must be calculated prior to installation")
        XCTAssertFalse(viewModel.formattedTotalSelectedSize.isEmpty)
        XCTAssertFalse(viewModel.isLaunching, "Execution must not proceed without user confirmation")
    }

    func testLaunchViewModelCancelDependencyResolutionAbortsLaunch() {
        let repo = GameProfileRepository()
        let launcher = GameLauncher(profileRepository: repo)
        let tempPrefixDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let prefixManager = PrefixManager(basePrefixDirectory: tempPrefixDir)
        let viewModel = LaunchViewModel(launcher: launcher, profileRepository: repo, prefixManager: prefixManager)

        viewModel.selectGame(gameId: "elden-ring")
        viewModel.offlineConsent = true
        viewModel.launch()
        XCTAssertTrue(viewModel.showDependencySheet)

        viewModel.cancelDependencyResolution()

        XCTAssertFalse(viewModel.showDependencySheet)
        XCTAssertFalse(viewModel.isDownloadingDependencies)
        XCTAssertTrue(viewModel.logs.contains("cancelled by user"))
    }
}
