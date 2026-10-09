import Foundation
import Observation
import MacOSGamingCore

@Observable
@MainActor
public final class DiagnosticsViewModel {
    private let systemDetector: SystemDetector
    private let validator: GameValidator

    public var systemReport: SystemReport?
    public var validationGameId: String = "dota-2"
    public var isValidating: Bool = false
    public var validationOutput: String = ""
    public var latestReport: GameValidationReport?

    public init(
        systemDetector: SystemDetector = SystemDetector(),
        validator: GameValidator = GameValidator()
    ) {
        self.systemDetector = systemDetector
        self.validator = validator
        runDoctor()
    }

    public func runDoctor() {
        self.systemReport = systemDetector.detect()
    }

    public func runValidation(dryRun: Bool = true) {
        guard !isValidating else { return }
        self.isValidating = true
        self.validationOutput = ""
        self.latestReport = nil

        let config = GameValidationConfig(
            gameId: validationGameId,
            timeoutSeconds: 15.0,
            isDryRun: dryRun
        )

        let validator = self.validator
        let buffer = ThreadSafeBuffer()

        Task.detached(priority: .userInitiated) { [weak self] in
            let result = validator.validate(config: config) { chunk in
                if let data = chunk.data(using: .utf8) {
                    buffer.append(data)
                }
                let current = buffer.stringValue()
                Task { @MainActor [weak self] in
                    self?.validationOutput = current
                }
            }

            Task { @MainActor [weak self] in
                self?.isValidating = false
                switch result {
                case .validated(let report):
                    self?.latestReport = report
                case .blockedBySentinel(_, let reason, _):
                    self?.validationOutput += "\n[!] Bloqueado por Sentinel: \(reason)\n"
                default:
                    self?.validationOutput += "\n[!] Validación no completada.\n"
                }
            }
        }
    }
}
