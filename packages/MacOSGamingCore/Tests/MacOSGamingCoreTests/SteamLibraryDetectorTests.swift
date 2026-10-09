import XCTest
@testable import MacOSGamingCore

final class SteamLibraryDetectorTests: XCTestCase {
    var tempSteamDir: URL!
    var tempSecondaryDir: URL!

    override func setUp() {
        super.setUp()
        let fm = FileManager.default
        let tempBase = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        tempSteamDir = tempBase.appendingPathComponent("Steam", isDirectory: true)
        tempSecondaryDir = tempBase.appendingPathComponent("SecondaryLibrary", isDirectory: true)

        try? fm.createDirectory(at: tempSteamDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: tempSecondaryDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let temp = tempSteamDir?.deletingLastPathComponent() {
            try? FileManager.default.removeItem(at: temp)
        }
        super.tearDown()
    }

    func testSteamDetectionWithMockFilesystem() throws {
        let fm = FileManager.default

        // 1. Setup primary library steamapps directory
        let steamapps = tempSteamDir.appendingPathComponent("steamapps", isDirectory: true)
        try fm.createDirectory(at: steamapps, withIntermediateDirectories: true)

        // 2. Setup secondary library
        let secondarySteamapps = tempSecondaryDir.appendingPathComponent("steamapps", isDirectory: true)
        try fm.createDirectory(at: secondarySteamapps, withIntermediateDirectories: true)

        // 3. Write libraryfolders.vdf
        let vdfContent = """
        "libraryfolders"
        {
            "0"
            {
                "path"    "\(tempSteamDir.path)"
            }
            "1"
            {
                "path"    "\(tempSecondaryDir.path)"
            }
        }
        """
        try vdfContent.write(to: steamapps.appendingPathComponent("libraryfolders.vdf"), atomically: true, encoding: .utf8)

        // 4. Write appmanifest_730.acf (Counter-Strike 2) in primary library
        let cs2Manifest = """
        "AppState"
        {
            "appid"        "730"
            "name"         "Counter-Strike 2"
            "installdir"   "Counter-Strike Global Offensive"
            "StateFlags"   "4"
        }
        """
        try cs2Manifest.write(to: steamapps.appendingPathComponent("appmanifest_730.acf"), atomically: true, encoding: .utf8)

        // Create mock executable for CS2
        let cs2Common = steamapps.appendingPathComponent("common/Counter-Strike Global Offensive/game/bin/win64", isDirectory: true)
        try fm.createDirectory(at: cs2Common, withIntermediateDirectories: true)
        fm.createFile(atPath: cs2Common.appendingPathComponent("cs2.exe").path, contents: "mock binary".data(using: .utf8))

        // 5. Write appmanifest_1245620.acf (Elden Ring) in secondary library
        let eldenManifest = """
        "AppState"
        {
            "appid"        "1245620"
            "name"         "ELDEN RING"
            "installdir"   "ELDEN RING"
            "StateFlags"   "4"
        }
        """
        try eldenManifest.write(to: secondarySteamapps.appendingPathComponent("appmanifest_1245620.acf"), atomically: true, encoding: .utf8)

        let eldenCommon = secondarySteamapps.appendingPathComponent("common/ELDEN RING/Game", isDirectory: true)
        try fm.createDirectory(at: eldenCommon, withIntermediateDirectories: true)
        fm.createFile(atPath: eldenCommon.appendingPathComponent("eldenring.exe").path, contents: "mock binary".data(using: .utf8))

        // 6. Test detector discovery
        let detector = SteamLibraryDetector(customSteamDirectory: tempSteamDir)
        let libraries = detector.discoverLibraryFolders()
        XCTAssertEqual(libraries.count, 2, "Should discover primary and secondary library folders")

        let apps = detector.detectInstalledApps()
        XCTAssertEqual(apps.count, 2, "Should discover both installed apps across libraries")

        // Validate Counter-Strike 2
        guard let cs2App = detector.findApp(appId: 730) else {
            XCTFail("Failed to find app 730")
            return
        }
        XCTAssertEqual(cs2App.name, "Counter-Strike 2")
        XCTAssertEqual(cs2App.profileId, "cs2", "Should map appId 730 to 'cs2' profile")
        XCTAssertNotNil(cs2App.executablePath, "Should locate cs2.exe")
        XCTAssertEqual(cs2App.executablePath?.lastPathComponent, "cs2.exe")

        // Validate Elden Ring
        guard let eldenApp = detector.findApp(forProfileId: "elden-ring") else {
            XCTFail("Failed to find Elden Ring by profile ID")
            return
        }
        XCTAssertEqual(eldenApp.appId, 1245620)
        XCTAssertEqual(eldenApp.profileId, "elden-ring")
        XCTAssertNotNil(eldenApp.executablePath)
        XCTAssertEqual(eldenApp.executablePath?.lastPathComponent, "eldenring.exe")
    }
}
