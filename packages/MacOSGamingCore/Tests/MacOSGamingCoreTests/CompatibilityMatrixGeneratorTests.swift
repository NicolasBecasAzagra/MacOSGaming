import XCTest
@testable import MacOSGamingCore

final class CompatibilityMatrixGeneratorTests: XCTestCase {

    func testCalculateBadgeCountsFromTargetProfiles() {
        let repo = GameProfileRepository()
        let profiles = repo.allProfiles()
        XCTAssertEqual(profiles.count, 8)

        let counts = CompatibilityMatrixGenerator.calculateBadgeCounts(profiles: profiles)

        XCTAssertEqual(counts.total, 8)
        XCTAssertEqual(counts.verified, 8)
        XCTAssertEqual(counts.nativeMacOS, 2, "Expected Dota 2 and League of Legends to be native")
        XCTAssertEqual(counts.likelyCompatible, 3, "Expected CS2, Elden Ring, GTA V to be likely compatible")
        XCTAssertEqual(counts.requiresWindows, 1, "Expected Rocket League to require Windows")
        XCTAssertEqual(counts.notSupported, 2, "Expected Fortnite and Valorant to be not supported")
        XCTAssertEqual(counts.playableTotal, 5, "Expected 2 native + 3 likely compatible = 5 playable")
        XCTAssertEqual(counts.blockedByAntiCheat, 2, "Expected Fortnite and Valorant to be blocked by kernel anti-cheat")
    }

    func testGenerateHTMLProducesValidHTML() {
        let repo = GameProfileRepository()
        let profiles = repo.allProfiles()
        let html = CompatibilityMatrixGenerator.generateHTML(profiles: profiles)

        XCTAssertTrue(html.contains("<!DOCTYPE html>"), "HTML must begin with DOCTYPE")
        XCTAssertTrue(html.contains("<html lang=\"en\">"), "HTML must declare english lang")
        XCTAssertTrue(html.contains("<title>Compatibility Matrix"), "HTML must include title")
        XCTAssertTrue(html.contains("id=\"search-input\""), "Must contain search input element")
        XCTAssertTrue(html.contains("id=\"anticheat-select\""), "Must contain anticheat select dropdown")
        XCTAssertTrue(html.contains("id=\"matrix-table\""), "Must contain matrix table")
        XCTAssertTrue(html.contains("id=\"matrix-tbody\""), "Must contain tbody element")
        XCTAssertTrue(html.contains("</html>"), "HTML must have closing html tag")

        // Verify all 8 game profiles are represented in the rows
        for profile in profiles {
            XCTAssertTrue(html.contains(profile.name), "HTML must contain game name \(profile.name)")
            XCTAssertTrue(html.contains(profile.id), "HTML must contain game id \(profile.id)")
        }
    }

    func testGenerateBadgesMarkdownFormat() {
        let counts = CompatibilityMatrixGenerator.BadgeCounts(
            total: 8,
            verified: 8,
            nativeMacOS: 2,
            likelyCompatible: 3,
            requiresWindows: 1,
            notSupported: 2,
            playableTotal: 5,
            blockedByAntiCheat: 2
        )

        let md = CompatibilityMatrixGenerator.generateBadgesMarkdown(counts: counts)

        XCTAssertTrue(md.contains("Profiles-8%20Cataloged"))
        XCTAssertTrue(md.contains("Confidence-8%20Verified"))
        XCTAssertTrue(md.contains("Playable-5%20Supported"))
        XCTAssertTrue(md.contains("Blocked-2%20Kernel%20Anti--Cheat"))
        XCTAssertTrue(md.contains("https://nicolasbecasazagra.github.io/MacOSGaming/compatibility.html"))
    }

    func testPythonGeneratorScriptProducesFreshHTML() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["scripts/generate_compatibility_page.py", "--check"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        XCTAssertNoThrow(try process.run())
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0, "Python compatibility generator script should verify HTML is fresh")
    }
}
