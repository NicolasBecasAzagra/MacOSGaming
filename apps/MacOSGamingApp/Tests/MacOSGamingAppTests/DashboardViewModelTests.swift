import XCTest
@testable import MacOSGamingApp
@testable import MacOSGamingCore

@MainActor
final class DashboardViewModelTests: XCTestCase {
    func testDashboardReflectsSystemReport() async {
        let viewModel = DashboardViewModel()
        
        // Assert report is populated
        XCTAssertNotNil(viewModel.systemReport)
        guard let report = viewModel.systemReport else { return }
        
        // Readiness score must be computed between 0 and 100
        XCTAssertGreaterThanOrEqual(report.readinessScore, 0)
        XCTAssertLessThanOrEqual(report.readinessScore, 100)
        
        // Chip model and OS should be valid non-empty strings
        XCTAssertFalse(report.chipModel.isEmpty)
        XCTAssertFalse(report.osMarketingName.isEmpty)
        XCTAssertFalse(report.osVersion.isEmpty)
        
        // Unified memory should be positive
        XCTAssertGreaterThan(report.unifiedMemoryGB, 0)
    }

    func testDashboardRefreshUpdatesState() async {
        let viewModel = DashboardViewModel()
        let initialReport = viewModel.systemReport
        XCTAssertNotNil(initialReport)
        
        viewModel.refreshDashboard()
        XCTAssertNotNil(viewModel.systemReport)
        XCTAssertFalse(viewModel.isLoading)
    }
}
