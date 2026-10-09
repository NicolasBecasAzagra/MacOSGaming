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
        // Tier 1: Enthusiast (32+ GB RAM, Apple Silicon, Sequoia+, Rosetta 2, 60 GB SSD) -> 100/100
        let enthusiastScore = SystemDetector.calculateReadinessScore(
            isAppleSilicon: true,
            memoryBytes: 32 * 1024 * 1024 * 1024,
            isSequoia: true,
            rosettaInstalled: true,
            freeDiskBytes: 60 * 1024 * 1024 * 1024
        )
        XCTAssertEqual(enthusiastScore, 100)

        // Tier 2: Recommended Baseline (16 GB RAM, Apple Silicon, Sequoia+, Rosetta 2, 60 GB SSD) -> 95/100
        let baseline16GBScore = SystemDetector.calculateReadinessScore(
            isAppleSilicon: true,
            memoryBytes: 16 * 1024 * 1024 * 1024,
            isSequoia: true,
            rosettaInstalled: true,
            freeDiskBytes: 60 * 1024 * 1024 * 1024
        )
        XCTAssertEqual(baseline16GBScore, 95)

        // Penalty Check: 8 GB RAM (< 16 GB) experiences a -10 penalty -> 65/100
        let penalized8GBScore = SystemDetector.calculateReadinessScore(
            isAppleSilicon: true,
            memoryBytes: 8 * 1024 * 1024 * 1024,
            isSequoia: true,
            rosettaInstalled: true,
            freeDiskBytes: 60 * 1024 * 1024 * 1024
        )
        XCTAssertEqual(penalized8GBScore, 65)
        XCTAssertTrue(
            penalized8GBScore < baseline16GBScore,
            "RAM < 16 GB must be penalized relative to the 16 GB recommended baseline"
        )

        // Severe Penalty Check: Under 8 GB RAM (e.g. 4 GB) experiences a -20 penalty -> 55/100
        let severePenaltyScore = SystemDetector.calculateReadinessScore(
            isAppleSilicon: true,
            memoryBytes: 4 * 1024 * 1024 * 1024,
            isSequoia: true,
            rosettaInstalled: true,
            freeDiskBytes: 60 * 1024 * 1024 * 1024
        )
        XCTAssertEqual(severePenaltyScore, 55)

        // Constrained low-spec system
        let constrainedScore = SystemDetector.calculateReadinessScore(
            isAppleSilicon: true,
            memoryBytes: 8 * 1024 * 1024 * 1024,
            isSequoia: false,
            rosettaInstalled: false,
            freeDiskBytes: 10 * 1024 * 1024 * 1024
        )
        XCTAssertEqual(constrainedScore, 25)

        // Extreme clamp check: Intel + 4 GB RAM + macOS 14 + no Rosetta -> clamped to 0
        let zeroScore = SystemDetector.calculateReadinessScore(
            isAppleSilicon: false,
            memoryBytes: 4 * 1024 * 1024 * 1024,
            isSequoia: false,
            rosettaInstalled: false,
            freeDiskBytes: 10 * 1024 * 1024 * 1024
        )
        XCTAssertEqual(zeroScore, 0, "Negative point sums must clamp at 0")
    }

    func testMacOSMarketingNameResolution() {
        XCTAssertEqual(SystemDetector.osMarketingName(forMajorVersion: 11), "Big Sur")
        XCTAssertEqual(SystemDetector.osMarketingName(forMajorVersion: 12), "Monterey")
        XCTAssertEqual(SystemDetector.osMarketingName(forMajorVersion: 13), "Ventura")
        XCTAssertEqual(SystemDetector.osMarketingName(forMajorVersion: 14), "Sonoma")
        XCTAssertEqual(SystemDetector.osMarketingName(forMajorVersion: 15), "Sequoia")
        XCTAssertEqual(SystemDetector.osMarketingName(forMajorVersion: 16), "Tahoe")
        XCTAssertEqual(SystemDetector.osMarketingName(forMajorVersion: 26), "Tahoe")
        XCTAssertEqual(SystemDetector.osMarketingName(forMajorVersion: 10), "Catalina")
    }

    func testAVX2SupportValidationByMajorVersion() {
        // macOS < 15 lacks AVX2 evaluation in Rosetta 2
        XCTAssertFalse(SystemDetector.validateAVX2Support(majorVersion: 13))
        XCTAssertFalse(SystemDetector.validateAVX2Support(majorVersion: 14))

        // macOS >= 15 supports AVX2 (Sequoia 15, Tahoe 16, etc.)
        XCTAssertTrue(SystemDetector.validateAVX2Support(majorVersion: 15))
        XCTAssertTrue(SystemDetector.validateAVX2Support(majorVersion: 16))
        XCTAssertTrue(SystemDetector.validateAVX2Support(majorVersion: 26))
    }

    func testDoctorReportContainsMarketingNameAndAVX2() {
        let detector = SystemDetector()
        let report = detector.detect()

        XCTAssertFalse(report.osMarketingName.isEmpty, "OS marketing name should not be empty")
        XCTAssertGreaterThanOrEqual(report.osMajorVersion, 10, "macOS major version must be >= 10")
        XCTAssertEqual(
            report.supportsAVX2,
            report.osMajorVersion >= 15,
            "AVX2 support flag should match majorVersion >= 15"
        )
    }
}
