import XCTest
@testable import MacOSGamingCore

final class DependencyManagerTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let temp = tempDirectory {
            try? FileManager.default.removeItem(at: temp)
        }
        super.tearDown()
    }

    func testDependencyStatusReportsCorrectOfficialSources() {
        let manager = DependencyManager(customRuntimesDirectory: tempDirectory)
        let deps = manager.checkDependencies()

        XCTAssertFalse(deps.isEmpty, "Dependencies list should not be empty")

        // 1. Wine-CX
        guard let wineDep = deps.first(where: { $0.name.contains("Wine-CX") }) else {
            XCTFail("Wine-CX dependency missing")
            return
        }
        XCTAssertEqual(wineDep.licenseType, "LGPL v2.1+")
        XCTAssertTrue(wineDep.officialSourceURL.contains("github.com/Gcenx/winecx"))

        // 2. DXMT
        guard let dxmtDep = deps.first(where: { $0.name.contains("DXMT") }) else {
            XCTFail("DXMT dependency missing")
            return
        }
        XCTAssertTrue(dxmtDep.officialSourceURL.contains("github.com/3Shain/dxmt"))
        XCTAssertTrue(dxmtDep.licenseType.contains("LGPL") || dxmtDep.licenseType.contains("MIT"))

        // 3. Apple D3DMetal (Strict notice)
        guard let d3dmetalDep = deps.first(where: { $0.name.contains("D3DMetal") }) else {
            XCTFail("D3DMetal dependency missing")
            return
        }
        XCTAssertTrue(d3dmetalDep.licenseType.contains("Evaluation License"))
        XCTAssertTrue(d3dmetalDep.installationInstructions.contains("developer.apple.com"))
    }

    func testEnsureRuntimeDirectoriesCreatesExpectedStructure() throws {
        let manager = DependencyManager(customRuntimesDirectory: tempDirectory)
        try manager.ensureRuntimeDirectories()

        let fm = FileManager.default
        XCTAssertTrue(fm.fileExists(atPath: tempDirectory.appendingPathComponent("wine").path))
        XCTAssertTrue(fm.fileExists(atPath: tempDirectory.appendingPathComponent("dxmt").path))
        XCTAssertTrue(fm.fileExists(atPath: tempDirectory.appendingPathComponent("dxvk").path))
        XCTAssertTrue(fm.fileExists(atPath: tempDirectory.appendingPathComponent("downloads").path))
    }
}
