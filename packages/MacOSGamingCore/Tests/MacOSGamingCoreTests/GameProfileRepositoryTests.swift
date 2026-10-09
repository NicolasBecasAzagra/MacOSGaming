import XCTest
@testable import MacOSGamingCore

final class GameProfileRepositoryTests: XCTestCase {
    func testAllEightTargetProfilesAreLoaded() {
        let repo = GameProfileRepository()
        let expectedIds = [
            "cs2",
            "dota-2",
            "rocket-league",
            "elden-ring",
            "gta-v",
            "fortnite",
            "valorant",
            "league-of-legends"
        ]

        for id in expectedIds {
            let profile = repo.profile(for: id)
            XCTAssertNotNil(profile, "Profile for '\(id)' must be loaded and non-nil")
            if let p = profile {
                XCTAssertEqual(p.id, id)
                XCTAssertFalse(p.name.isEmpty)
                XCTAssertFalse(p.sources.isEmpty, "Profile '\(id)' must contain at least one verified source")
                XCTAssertFalse(p.lastVerified.isEmpty, "Profile '\(id)' must contain last_verified date")
                XCTAssertEqual(p.confidenceLevel, .verified, "Target profile '\(id)' must be verified")
            }
        }
    }
}
