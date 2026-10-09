import Foundation
import Observation
import MacOSGamingCore

@Observable
@MainActor
public final class LaunchViewModel {
    private let launcher: GameLauncher
    private let profileRepository: GameProfileRepository
    private var activeTask: Task<Void, Never>?

    public var selectedGameId: String = "dota-2"
    public var selectedProfile: GameProfile?
    public var isLaunching: Bool = false
    public var logs: String = ""
    public var exitCode: Int32? = nil
    public var wasBlockedBySentinel: Bool = false
    public var blockReason: String = ""
    public var alternatives: [String] = []

    // Launch options
    public var offlineConsent: Bool = false
    public var isDryRun: Bool = false
    public var timeoutSeconds: Double? = 30.0
    public var autoRetry: Bool = true
    public var customPath: String = ""

    public init(
        launcher: GameLauncher = GameLauncher(),
        profileRepository: GameProfileRepository = GameProfileRepository()
    ) {
        self.launcher = launcher
        self.profileRepository = profileRepository
        self.selectedProfile = profileRepository.profile(for: selectedGameId)
    }

    public func selectGame(gameId: String) {
        self.selectedGameId = gameId
        self.selectedProfile = profileRepository.profile(for: gameId)
        self.wasBlockedBySentinel = false
        self.blockReason = ""
        self.alternatives = []
        self.exitCode = nil
        self.logs = ""
    }

    public func launch() {
        guard !isLaunching else { return }
        self.isLaunching = true
        self.logs = ""
        self.exitCode = nil
        self.wasBlockedBySentinel = false

        let customURL = customPath.isEmpty ? nil : URL(fileURLWithPath: customPath)
        let config = LaunchConfiguration(
            gameId: selectedGameId,
            customExecutablePath: customURL,
            offlineConsent: offlineConsent,
            isDryRun: isDryRun,
            timeoutSeconds: timeoutSeconds,
            enableSignalHandling: true,
            autoRetryWithAlternativeConfig: autoRetry
        )

        let launcher = self.launcher
        let buffer = ThreadSafeBuffer()

        activeTask = Task.detached(priority: .userInitiated) { [weak self] in
            let result = launcher.launch(configuration: config) { chunk in
                if let data = chunk.data(using: .utf8) {
                    buffer.append(data)
                }
                let current = buffer.stringValue()
                Task { @MainActor [weak self] in
                    self?.logs = current
                }
            }

            Task { @MainActor [weak self] in
                self?.isLaunching = false
                switch result {
                case .blockedBySentinel(_, let reason, let alts):
                    self?.wasBlockedBySentinel = true
                    self?.blockReason = reason
                    self?.alternatives = alts
                    self?.exitCode = 2
                    self?.logs += "\n[!] Lanzamiento bloqueado por Anti-Cheat Sentinel:\n\(reason)\n"

                case .launched(_, let execResult, _, let retryAttempted, let altConfig):
                    self?.exitCode = execResult.exitCode
                    if retryAttempted, let alt = altConfig {
                        self?.logs += "\n[*] Reintento automático ejecutado: \(alt)\n"
                    }
                    self?.logs += "\nProceso finalizado con código: \(execResult.exitCode)\n"

                case .profileNotFound(let id):
                    self?.logs += "\n[Error] Perfil '\(id)' no encontrado.\n"
                    self?.exitCode = 1

                case .executableNotFound(_, let paths, let suggestion):
                    self?.logs += "\n[Error] Ejecutable no encontrado en: \(paths.joined(separator: ", "))\n\(suggestion)\n"
                    self?.exitCode = 1

                case .runtimeMissing(let dep, let inst):
                    self?.logs += "\n[Error] Dependencia faltante: \(dep)\n\(inst)\n"
                    self?.exitCode = 1
                }
            }
        }
    }

    public func cancel() {
        if isLaunching {
            activeTask?.cancel()
            activeTask = nil
            isLaunching = false
            logs += "\n[ProcessRunner] Cancelación solicitada por el usuario en la UI.\n"
        }
    }
}
