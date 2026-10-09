import XCTest
@testable import MacOSGamingApp
@testable import MacOSGamingCore

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testTelemetryIsDisabledByDefault() {
        let viewModel = SettingsViewModel()
        // Critical requirement: telemetry must be OFF by default
        XCTAssertFalse(viewModel.telemetryEnabled, "Telemetry must be OFF by default according to project specifications")
    }

    func testDependenciesAreChecked() {
        let viewModel = SettingsViewModel()
        XCTAssertFalse(viewModel.dependencies.isEmpty)

        let names = viewModel.dependencies.map(\.name)
        XCTAssertTrue(names.contains { $0.contains("Rosetta") })
        XCTAssertTrue(names.contains { $0.contains("Wine") })
        XCTAssertTrue(names.contains { $0.contains("DXMT") })
    }

    func testPathsAreConfigured() {
        let viewModel = SettingsViewModel()
        XCTAssertFalse(viewModel.steamRootPath.isEmpty)
        XCTAssertFalse(viewModel.runtimesPath.isEmpty)
        XCTAssertTrue(viewModel.steamRootPath.contains("Steam"))
        XCTAssertTrue(viewModel.runtimesPath.contains("MacOSGaming/runtimes"))
    }
}
