import XCTest
@testable import MacOSGamingCore

final class AntiCheatSentinelTests: XCTestCase {
    let repo = GameProfileRepository()
    let sentinel = AntiCheatSentinel()

    func testValorantIsStrictlyBlocked() {
        guard let profile = repo.profile(for: "valorant") else {
            XCTFail("Valorant profile not found")
            return
        }

        let decision = sentinel.evaluate(profile: profile, userConsentOffline: false)
        guard case .blocked(let p, let reason, let alternatives) = decision else {
            XCTFail("Valorant must be blocked by sentinel")
            return
        }

        XCTAssertEqual(p.id, "valorant")
        XCTAssertTrue(reason.contains("Vanguard"), "Reason must mention Vanguard")
        XCTAssertFalse(alternatives.isEmpty, "Must provide legal alternatives")

        // Even if user requests offline, Vanguard games must remain blocked
        let offlineAttempt = sentinel.evaluate(profile: profile, userConsentOffline: true)
        guard case .blocked = offlineAttempt else {
            XCTFail("Valorant must remain blocked even if user requests offline")
            return
        }
    }

    func testFortniteIsStrictlyBlocked() {
        guard let profile = repo.profile(for: "fortnite") else {
            XCTFail("Fortnite profile not found")
            return
        }

        let decision = sentinel.evaluate(profile: profile, userConsentOffline: false)
        guard case .blocked(let p, let reason, _) = decision else {
            XCTFail("Fortnite must be blocked by sentinel")
            return
        }
        XCTAssertEqual(p.id, "fortnite")
        XCTAssertTrue(reason.contains("anti-cheat") || reason.contains("BattlEye"))
    }

    func testNativeGamesArePermitted() {
        guard let dota = repo.profile(for: "dota-2"),
              let lol = repo.profile(for: "league-of-legends") else {
            XCTFail("Dota 2 or LoL profile not found")
            return
        }

        let dotaDecision = sentinel.evaluate(profile: dota)
        guard case .permitted(let p1, _, let backend1) = dotaDecision else {
            XCTFail("Dota 2 must be permitted directly")
            return
        }
        XCTAssertEqual(p1.id, "dota-2")
        XCTAssertEqual(backend1, .metalNative)

        let lolDecision = sentinel.evaluate(profile: lol)
        guard case .permitted(let p2, _, let backend2) = lolDecision else {
            XCTFail("League of Legends must be permitted directly")
            return
        }
        XCTAssertEqual(p2.id, "league-of-legends")
        XCTAssertEqual(backend2, .metalNative)
    }

    func testGTAVOfflineModeBehavior() {
        guard let gta = repo.profile(for: "gta-v") else {
            XCTFail("GTA V profile not found")
            return
        }

        // Without consent, it should prompt/block online
        let blockedDecision = sentinel.evaluate(profile: gta, userConsentOffline: false)
        guard case .blocked = blockedDecision else {
            XCTFail("GTA V must block default online launch without offline consent")
            return
        }

        // With consent, it should permit offline single-player with -nobattleye
        let offlineDecision = sentinel.evaluate(profile: gta, userConsentOffline: true)
        guard case .offlineOnly(_, _, let args, _) = offlineDecision else {
            XCTFail("GTA V must permit offline mode with consent")
            return
        }
        XCTAssertTrue(args.contains("-nobattleye"), "GTA V must pass -nobattleye flag")
    }
}
