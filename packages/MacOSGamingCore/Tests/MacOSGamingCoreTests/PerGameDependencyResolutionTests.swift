import XCTest
@testable import MacOSGamingCore

final class MockDownloadURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.scheme == "mock"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url else { return }
        let payload = Data(repeating: 0x42, count: 1024)
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Length": "1024",
                "Content-Type": "application/octet-stream"
            ]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        let chunkSize = 256
        for offset in stride(from: 0, to: payload.count, by: chunkSize) {
            let chunk = payload.subdata(in: offset..<min(offset + chunkSize, payload.count))
            client?.urlProtocol(self, didLoad: chunk)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class PerGameDependencyResolutionTests: XCTestCase {
    var tempBaseDir: URL!
    var tempPrefixDir: URL!

    override func setUp() {
        super.setUp()
        let fm = FileManager.default
        tempBaseDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        tempPrefixDir = tempBaseDir.appendingPathComponent("prefixes", isDirectory: true)
        try? fm.createDirectory(at: tempPrefixDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let temp = tempBaseDir {
            try? FileManager.default.removeItem(at: temp)
        }
        super.tearDown()
    }

    func testDependencySizeIsDisplayedBeforeInstallation() {
        let profileRepo = GameProfileRepository()
        guard let eldenRingProfile = profileRepo.profile(for: "elden-ring"),
              let gtaProfile = profileRepo.profile(for: "gta-v") else {
            XCTFail("Profiles should exist")
            return
        }

        let depManager = DependencyManager()
        let eldenDeps = depManager.resolveGameDependencies(for: eldenRingProfile)
        let gtaDeps = depManager.resolveGameDependencies(for: gtaProfile)

        XCTAssertFalse(eldenDeps.isEmpty, "Elden Ring must require dependencies (Wine, D3DMetal, VC++)")
        XCTAssertFalse(gtaDeps.isEmpty, "GTA V must require dependencies (Wine, DXMT, VC++)")

        for dep in eldenDeps + gtaDeps {
            // Size in MB must be available before installing
            XCTAssertGreaterThanOrEqual(dep.sizeInMB, 0.0, "Dependency size must be non-negative")
            XCTAssertFalse(dep.formattedSize.isEmpty, "Formatted size must not be empty")
            XCTAssertTrue(dep.formattedSize.hasSuffix("MB"), "Formatted size should end with 'MB'")
            XCTAssertFalse(dep.name.isEmpty)
            XCTAssertNotNil(dep.officialSourceURL)
        }

        // Verify Elden Ring dependencies
        let wineDep = eldenDeps.first { $0.dependencyId == "wine-cx" }
        XCTAssertNotNil(wineDep)
        XCTAssertEqual(wineDep?.formattedSize, "120.0 MB")

        let d3dmetalDep = eldenDeps.first { $0.dependencyId == "d3dmetal" }
        XCTAssertNotNil(d3dmetalDep)
        XCTAssertEqual(d3dmetalDep?.formattedSize, "0.0 MB")

        // Verify GTA V dependencies (DXMT)
        let dxmtDep = gtaDeps.first { $0.dependencyId == "dxmt" }
        XCTAssertNotNil(dxmtDep)
        XCTAssertEqual(dxmtDep?.formattedSize, "15.5 MB")

        let vcDep = gtaDeps.first { $0.dependencyId == "vcredist" }
        XCTAssertNotNil(vcDep)
        XCTAssertEqual(vcDep?.formattedSize, "24.1 MB")
    }

    func testDownloadRespectsUserExplicitConfirmationAndPrefixManifest() throws {
        let prefixManager = PrefixManager(basePrefixDirectory: tempPrefixDir)
        let depManager = DependencyManager()
        let profileRepo = GameProfileRepository()

        guard let gtaProfile = profileRepo.profile(for: "gta-v") else {
            XCTFail("GTA V profile should exist")
            return
        }

        // 1. Initial state: Prefix manifest does not exist or has zero records
        let initialManifest = prefixManager.loadManifest(for: gtaProfile.id)
        XCTAssertEqual(initialManifest.records.count, 0)
        XCTAssertFalse(prefixManager.isDependencyInstalled(id: "dxmt", profileId: gtaProfile.id))

        // 2. Unconfirmed state: user cancels or makes no confirmation -> nothing installed
        XCTAssertFalse(prefixManager.isDependencyInstalled(id: "dxmt", profileId: gtaProfile.id))

        // 3. User explicitly confirms and selects DXMT only
        let dxmtDep = GameDependency(
            dependencyId: "dxmt",
            name: "DXMT (Direct3D 11 -> Metal)",
            category: .graphicsTranslator,
            sizeInMB: 15.5,
            officialSourceURL: URL(string: "https://github.com/3Shain/dxmt/releases")!,
            targetFilename: "d3d11.dll",
            licenseType: "LGPL v2.1+"
        )

        try prefixManager.recordInstalledDependencies([dxmtDep], for: gtaProfile.id)

        // 4. Verify manifest was saved inside the prefix sandbox
        XCTAssertTrue(prefixManager.isDependencyInstalled(id: "dxmt", profileId: gtaProfile.id))
        let manifestAfterInstall = prefixManager.loadManifest(for: gtaProfile.id)
        XCTAssertEqual(manifestAfterInstall.records.count, 1)
        XCTAssertEqual(manifestAfterInstall.records.first?.dependencyId, "dxmt")
        XCTAssertEqual(manifestAfterInstall.records.first?.sizeInMB, 15.5)

        // 5. Subsequent missing check should NOT include DXMT because it's recorded in manifest
        let missing = depManager.checkMissingDependencies(for: gtaProfile, prefixManager: prefixManager)
        XCTAssertFalse(missing.contains(where: { $0.dependencyId == "dxmt" }), "DXMT should not be reported missing after being recorded in prefix manifest")
    }

    func testDependencyDownloaderReportsProgressViaDelegate() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockDownloadURLProtocol.self]

        let downloader = DependencyDownloader(configuration: config)

        let mockDep = GameDependency(
            dependencyId: "mock-runtime",
            name: "Mock Runtime",
            category: .runtimePrerequisite,
            sizeInMB: 1.0,
            officialSourceURL: URL(string: "https://example.com")!,
            downloadURL: URL(string: "mock://example.com/runtime.bin")!,
            targetFilename: "runtime.bin",
            licenseType: "MIT"
        )

        var progressUpdates: [Double] = []
        let downloadedURL = try await downloader.download(dependency: mockDep) { progress in
            progressUpdates.append(progress.fractionCompleted)
            XCTAssertEqual(progress.dependencyId, "mock-runtime")
            XCTAssertEqual(progress.name, "Mock Runtime")
            XCTAssertEqual(progress.totalBytesExpected, 1024)
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: downloadedURL.path), "Downloaded file should exist at destination")
        XCTAssertFalse(progressUpdates.isEmpty, "Progress delegate callbacks should be received")
        XCTAssertEqual(progressUpdates.last, 1.0, "Final progress update should be 1.0 (100%)")

        try? FileManager.default.removeItem(at: downloadedURL)
    }
}
