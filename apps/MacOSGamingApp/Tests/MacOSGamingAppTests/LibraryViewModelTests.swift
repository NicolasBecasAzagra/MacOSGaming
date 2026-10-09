import XCTest
@testable import MacOSGamingApp
@testable import MacOSGamingCore

@MainActor
final class LibraryViewModelTests: XCTestCase {
    func testLibraryLoadsProfilesAndDetectsApps() {
        let viewModel = LibraryViewModel()
        XCTAssertFalse(viewModel.items.isEmpty)
        
        // Should contain verified profiles like dota-2, elden-ring, valorant
        let ids = viewModel.items.map(\.id)
        XCTAssertTrue(ids.contains("dota-2"))
        XCTAssertTrue(ids.contains("elden-ring"))
        XCTAssertTrue(ids.contains("valorant"))
    }

    func testLibrarySearchFiltersItems() {
        let viewModel = LibraryViewModel()
        viewModel.searchQuery = "elden"
        let filtered = viewModel.filteredItems

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, "elden-ring")
    }

    func testLibraryCompatibilityFilters() {
        let viewModel = LibraryViewModel()

        viewModel.selectedFilter = .all
        let allCount = viewModel.filteredItems.count
        XCTAssertGreaterThan(allCount, 0)

        viewModel.selectedFilter = .native
        let nativeItems = viewModel.filteredItems
        for item in nativeItems {
            XCTAssertEqual(item.compatibilityStatus, .nativeMacOS)
        }

        viewModel.selectedFilter = .compatible
        let compatibleItems = viewModel.filteredItems
        for item in compatibleItems {
            XCTAssertEqual(item.compatibilityStatus, .likelyCompatible)
        }

        viewModel.selectedFilter = .blocked
        let blockedItems = viewModel.filteredItems
        for item in blockedItems {
            let isKernelOrBlocked = item.compatibilityStatus == .notSupported ||
                item.profile?.launchPolicy == .blockKernelAnticheat ||
                (item.profile?.antiCheat.type == .kernelRing0)
            XCTAssertTrue(isKernelOrBlocked)
        }
    }
}
