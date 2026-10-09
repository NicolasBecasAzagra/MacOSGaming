import XCTest
@testable import MacOSGamingCore

final class PrefixManagerTests: XCTestCase {
    func testCreateIsolatedPrefix() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let manager = PrefixManager(basePrefixDirectory: tempDir)
        let info = try manager.createIsolatedPrefix(for: "test-game")

        XCTAssertTrue(info.isInitialized)
        XCTAssertTrue(FileManager.default.fileExists(atPath: info.driveCDirectory.path))

        let system32 = info.driveCDirectory.appendingPathComponent("windows/system32")
        XCTAssertTrue(FileManager.default.fileExists(atPath: system32.path))

        let configFile = info.prefixDirectory.appendingPathComponent("sandbox_config.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: configFile.path))
    }
}
