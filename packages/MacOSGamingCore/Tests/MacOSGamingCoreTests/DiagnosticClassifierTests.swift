import XCTest
@testable import MacOSGamingCore

final class DiagnosticClassifierTests: XCTestCase {
    let classifier = DiagnosticClassifier()

    func testVanguardAbortClassification() {
        let log = "0024:err:module:open_builtin_file cannot open .so lib for L\"C:\\\\Riot\\\\vgk.sys\""
        let match = classifier.classify(line: log)

        XCTAssertNotNil(match)
        XCTAssertEqual(match?.category, .antiCheatDriverAbort)
        XCTAssertEqual(match?.severity, .critical)
        XCTAssertTrue(match?.explanation.contains("Vanguard") ?? false)
    }

    func testIllegalInstructionClassification() {
        let log = "Process 4125 exited with signal SIGILL (STATUS_ILLEGAL_INSTRUCTION)"
        let match = classifier.classify(line: log)

        XCTAssertNotNil(match)
        XCTAssertEqual(match?.category, .unsupportedInstruction)
        XCTAssertEqual(match?.severity, .critical)
        XCTAssertTrue(match?.recommendation.contains("ROSETTA_ADVERTISE_AVX") ?? false)
    }

    func testMissingVCRuntimeClassification() {
        let log = "err:module:import_dll Library MSVCP140.dll (which is needed by L\"game.exe\") not found"
        let match = classifier.classify(line: log)

        XCTAssertNotNil(match)
        XCTAssertEqual(match?.category, .missingPrerequisite)
        XCTAssertEqual(match?.severity, .warning)
        XCTAssertTrue(match?.recommendation.contains("vcrun") ?? false)
    }

    func testCleanLogProducesZeroMatches() {
        let log = """
        === [MacOSGaming Sandbox Test Runner] ===
        Checking anti-cheat status: No kernel anti-cheat active in test sandbox
        === Test Harness Completed Successfully ===
        """
        let matches = classifier.analyze(log: log)
        XCTAssertTrue(matches.isEmpty, "Clean log should not trigger error diagnostics")
    }
}
