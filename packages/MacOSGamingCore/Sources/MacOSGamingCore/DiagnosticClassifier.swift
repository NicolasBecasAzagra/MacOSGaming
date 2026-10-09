import Foundation

public enum DiagnosticCategory: String, Sendable, Equatable {
    case missingPrerequisite = "missing_prerequisite"
    case unsupportedInstruction = "unsupported_instruction"
    case antiCheatDriverAbort = "anticheat_driver_abort"
    case graphicsApiFailure = "graphics_api_failure"
    case generalError = "general_error"
}

public enum DiagnosticSeverity: String, Sendable, Equatable {
    case critical = "CRITICAL"
    case warning = "WARNING"
    case info = "INFO"
}

public struct DiagnosticMatch: Sendable, Equatable {
    public let category: DiagnosticCategory
    public let severity: DiagnosticSeverity
    public let matchedPattern: String
    public let explanation: String
    public let recommendation: String

    public init(
        category: DiagnosticCategory,
        severity: DiagnosticSeverity,
        matchedPattern: String,
        explanation: String,
        recommendation: String
    ) {
        self.category = category
        self.severity = severity
        self.matchedPattern = matchedPattern
        self.explanation = explanation
        self.recommendation = recommendation
    }
}

public struct DiagnosticClassifier: Sendable {
    public init() {}

    public func classify(line: String) -> DiagnosticMatch? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        // 1. Anti-Cheat Driver Aborts
        if trimmed.contains("vgk.sys") || trimmed.contains("Vanguard") {
            return DiagnosticMatch(
                category: .antiCheatDriverAbort,
                severity: .critical,
                matchedPattern: "vgk.sys / Vanguard",
                explanation: "Riot Vanguard kernel-mode driver failed to initialize because macOS XNU cannot load Windows NT Ring-0 drivers.",
                recommendation: "Valorant cannot run on macOS. Please use a physical Windows PC with UEFI Secure Boot and TPM 2.0."
            )
        }

        if trimmed.contains("BEDaisy.sys") || trimmed.contains("BattlEye") {
            return DiagnosticMatch(
                category: .antiCheatDriverAbort,
                severity: .critical,
                matchedPattern: "BEDaisy.sys / BattlEye",
                explanation: "BattlEye kernel-mode driver failed to start under Wine.",
                recommendation: "Launch in offline mode if supported (e.g. use '-nobattleye' for GTA V Story Mode), or use a Windows PC."
            )
        }

        if trimmed.contains("EasyAntiCheat.sys") || trimmed.contains("EasyAntiCheat") {
            return DiagnosticMatch(
                category: .antiCheatDriverAbort,
                severity: .critical,
                matchedPattern: "EasyAntiCheat.sys",
                explanation: "Easy Anti-Cheat Windows driver failed to start in user-mode Darwin task.",
                recommendation: "Online multiplayer is unsupported. Run in offline single-player mode if permitted by the game."
            )
        }

        // 2. Unsupported Instructions (AVX / CPUID)
        if trimmed.contains("STATUS_ILLEGAL_INSTRUCTION") || trimmed.contains("SIGILL") || trimmed.contains("illegal instruction") {
            return DiagnosticMatch(
                category: .unsupportedInstruction,
                severity: .critical,
                matchedPattern: "STATUS_ILLEGAL_INSTRUCTION / SIGILL",
                explanation: "The application attempted to execute an unsupported CPU instruction (such as AVX/AVX2 on pre-Sequoia macOS, or AVX-512).",
                recommendation: "Ensure you are running macOS Sequoia (15.x+) and verify that the environment variable 'ROSETTA_ADVERTISE_AVX=1' is set."
            )
        }

        // 3. Missing Prerequisites (Visual C++ / DirectX runtimes)
        if trimmed.contains("MSVCP140.dll") || trimmed.contains("VCRUNTIME140.dll") || trimmed.contains("msvcp") {
            return DiagnosticMatch(
                category: .missingPrerequisite,
                severity: .warning,
                matchedPattern: "VCRUNTIME / MSVCP DLL",
                explanation: "The Microsoft Visual C++ 2015-2022 Redistributable runtime DLL is missing from the prefix.",
                recommendation: "Install the official vcrun2022 runtime into the prefix sandbox using 'winetricks vcrun2022'."
            )
        }

        if trimmed.contains("d3dx11") || trimmed.contains("d3dx9") || trimmed.contains("0x80004005") {
            return DiagnosticMatch(
                category: .missingPrerequisite,
                severity: .warning,
                matchedPattern: "DirectX runtime / 0x80004005",
                explanation: "DirectX helper library or COM component initialization failure.",
                recommendation: "Install DirectX End-User Runtimes (June 2010) into the prefix, or switch graphics translator backend."
            )
        }

        // 4. Graphics API Failures
        if trimmed.contains("CreateDevice failed") || trimmed.contains("D3D12 device creation failed") {
            return DiagnosticMatch(
                category: .graphicsApiFailure,
                severity: .critical,
                matchedPattern: "D3D device creation failed",
                explanation: "Failed to create Direct3D device. The selected translation backend (DXMT or D3DMetal) could not bind to Metal.",
                recommendation: "Verify that Metal is supported on your GPU and that the required translation libraries are present."
            )
        }

        return nil
    }

    public func analyze(log: String) -> [DiagnosticMatch] {
        var results: [DiagnosticMatch] = []
        var seenPatterns = Set<String>()

        let lines = log.components(separatedBy: .newlines)
        for line in lines {
            if let match = classify(line: line) {
                if !seenPatterns.contains(match.matchedPattern) {
                    seenPatterns.insert(match.matchedPattern)
                    results.append(match)
                }
            }
        }

        return results
    }
}
