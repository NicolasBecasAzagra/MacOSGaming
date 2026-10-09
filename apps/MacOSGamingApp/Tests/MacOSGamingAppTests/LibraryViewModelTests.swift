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

    func testUnprofiledSteamGameAppearsAsGeneric() throws {
        let fm = FileManager.default
        let tempBase = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let tempSteam = tempBase.appendingPathComponent("Steam", isDirectory: true)
        let steamapps = tempSteam.appendingPathComponent("steamapps", isDirectory: true)
        try fm.createDirectory(at: steamapps, withIntermediateDirectories: true)

        defer {
            try? fm.removeItem(at: tempBase)
        }

        // Write manifest for an unprofiled indie game (App ID 888999)
        let unprofiledManifest = """
        "AppState"
        {
            "appid"        "888999"
            "name"         "Deep Space Miner"
            "installdir"   "Deep Space Miner"
            "StateFlags"   "4"
        }
        """
        try unprofiledManifest.write(
            to: steamapps.appendingPathComponent("appmanifest_888999.acf"),
            atomically: true,
            encoding: .utf8
        )

        let detector = SteamLibraryDetector(customSteamDirectory: tempSteam)
        let viewModel = LibraryViewModel(steamDetector: detector)

        // Find the unprofiled game in library items
        guard let item = viewModel.items.first(where: { $0.steamApp?.appId == 888999 }) else {
            XCTFail("Unprofiled Steam game should be detected and present in library items")
            return
        }

        XCTAssertEqual(item.name, "Deep Space Miner")
        XCTAssertEqual(item.profileState, .generic, "Unprofiled Steam game must have profileState == .generic")
        XCTAssertTrue(item.isGeneric, "isGeneric helper should be true")
        XCTAssertFalse(item.isOptimized, "isOptimized helper should be false")
        XCTAssertNil(item.profile, "Unprofiled game should have nil profile")
        XCTAssertTrue(item.isInstalledInSteam)

        // Verify profile request URL generation
        let requestURL = viewModel.profileRequestURL(for: item)
        XCTAssertTrue(requestURL.absoluteString.contains("template=profile_request.yml"))
        XCTAssertTrue(requestURL.absoluteString.contains("steam_app_id=888999"))
        XCTAssertTrue(requestURL.absoluteString.contains("deep-space-miner"))
    }
}
