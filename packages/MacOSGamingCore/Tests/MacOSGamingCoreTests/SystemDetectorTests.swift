import XCTest
@testable import MacOSGamingCore

final class SystemDetectorTests: XCTestCase {
    func testSystemDetectionProducesValidReport() {
        let detector = SystemDetector()
        let report = detector.detect()

        XCTAssertFalse(report.chipModel.isEmpty, "Chip model should not be empty")
        XCTAssertGreaterThan(report.cpuCores, 0, "CPU core count should be positive")
        XCTAssertGreaterThan(report.unifiedMemoryBytes, 0, "Memory bytes should be positive")
        XCTAssertFalse(report.gpuName.isEmpty, "GPU name should be populated")
        XCTAssertFalse(report.osVersion.isEmpty, "OS version string should be populated")
        XCTAssertGreaterThanOrEqual(report.readinessScore, 0, "Readiness score must be >= 0")
        XCTAssertLessThanOrEqual(report.readinessScore, 100, "Readiness score must be <= 100")
    }

    func testReadinessScoreCalculation() {
        let highEndScore = SystemDetector.calculateReadinessScore(
            isAppleSilicon: true,
            memoryBytes: 16 * 1024 * 1024 * 1024,
            isSequoia: true,
            rosettaInstalled: true,
            freeDiskBytes: 60 * 1024 * 1024 * 1024
        )
        XCTAssertEqual(highEndScore, 100)

        let baselineScore = SystemDetector.calculateReadinessScore(
            isAppleSilicon: true,
            memoryBytes: 8 * 1024 * 1024 * 1024,
            isSequoia: false,
            rosettaInstalled: false,
            freeDiskBytes: 10 * 1024 * 1024 * 1024
        )
        XCTAssertEqual(baselineScore, 55)
    }
}
