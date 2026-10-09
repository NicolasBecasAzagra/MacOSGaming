import XCTest
@testable import MacOSGamingApp
@testable import MacOSGamingCore

@MainActor
final class DiagnosticsViewModelTests: XCTestCase {
    func testDoctorInitializesSystemReport() {
        let viewModel = DiagnosticsViewModel()
        XCTAssertNotNil(viewModel.systemReport)
        XCTAssertFalse(viewModel.isValidating)
    }

    func testValidationDryRunExecutesAsynchronously() async throws {
        let viewModel = DiagnosticsViewModel()
        viewModel.validationGameId = "dota-2"

        viewModel.runValidation(dryRun: true)

        let deadline = Date().addingTimeInterval(5.0)
        while viewModel.isValidating && Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        XCTAssertFalse(viewModel.isValidating)
        XCTAssertNotNil(viewModel.latestReport)
        XCTAssertEqual(viewModel.latestReport?.gameId, "dota-2")
    }
}
