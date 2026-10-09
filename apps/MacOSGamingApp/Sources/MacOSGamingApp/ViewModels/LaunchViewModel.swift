import Foundation
import Observation
import MacOSGamingCore

@Observable
@MainActor
public final class LaunchViewModel {
    private let launcher: GameLauncher
    private let profileRepository: GameProfileRepository
    private let dependencyManager: DependencyManager
    private let prefixManager: PrefixManager
    private let dependencyDownloader: DependencyDownloader
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

    // Per-Game Dependency Resolution
    public var showDependencySheet: Bool = false
    public var missingDependencies: [GameDependency] = []
    public var selectedDependencyIds: Set<String> = []
    public var isDownloadingDependencies: Bool = false
    public var downloadProgress: Double = 0.0
    public var downloadStatusText: String = ""
    public var downloadErrorMessage: String? = nil

    public var totalSelectedSizeMB: Double {
        missingDependencies
            .filter { selectedDependencyIds.contains($0.dependencyId) }
            .reduce(0.0) { $0 + $1.sizeInMB }
    }

    public var formattedTotalSelectedSize: String {
        String(format: "%.1f MB", totalSelectedSizeMB)
    }

    public init(
        launcher: GameLauncher = GameLauncher(),
        profileRepository: GameProfileRepository = GameProfileRepository(),
        dependencyManager: DependencyManager = DependencyManager(),
        prefixManager: PrefixManager = PrefixManager(),
        dependencyDownloader: DependencyDownloader = DependencyDownloader()
    ) {
        self.launcher = launcher
        self.profileRepository = profileRepository
        self.dependencyManager = dependencyManager
        self.prefixManager = prefixManager
        self.dependencyDownloader = dependencyDownloader
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
        self.showDependencySheet = false
        self.missingDependencies = []
    }

    public func toggleDependencySelection(_ id: String) {
        if selectedDependencyIds.contains(id) {
            selectedDependencyIds.remove(id)
        } else {
            selectedDependencyIds.insert(id)
        }
    }

    public func launch() {
        guard !isLaunching else { return }

        // 1. Evaluate Sentinel block immediately for kernel anti-cheat titles
        if let profile = selectedProfile {
            let sentinelDecision = AntiCheatSentinel().evaluate(profile: profile, userConsentOffline: offlineConsent)
            if case .blocked(_, let reason, let alts) = sentinelDecision {
                self.wasBlockedBySentinel = true
                self.blockReason = reason
                self.alternatives = alts
                self.exitCode = 2
                self.logs = "\n[!] Launch blocked by Anti-Cheat Sentinel:\n\(reason)\n"
                return
            }
        }

        // 2. Check for missing dependencies before execution (unless dry-run)
        if !isDryRun, let profile = selectedProfile {
            let missing = dependencyManager.checkMissingDependencies(for: profile, prefixManager: prefixManager)
            if !missing.isEmpty {
                self.missingDependencies = missing
                self.selectedDependencyIds = Set(missing.map(\.dependencyId))
                self.showDependencySheet = true
                self.downloadErrorMessage = nil
                return
            }
        }

        executeProcess()
    }

    public func installSelectedDependencies() {
        guard !isDownloadingDependencies else { return }
        guard let profile = selectedProfile else { return }

        let toDownload = missingDependencies.filter { selectedDependencyIds.contains($0.dependencyId) }
        guard !toDownload.isEmpty else {
            showDependencySheet = false
            executeProcess()
            return
        }

        self.isDownloadingDependencies = true
        self.downloadErrorMessage = nil
        self.downloadProgress = 0.0

        let downloader = self.dependencyDownloader
        let pManager = self.prefixManager

        Task {
            do {
                for (index, dep) in toDownload.enumerated() {
                    let depBaseProgress = Double(index) / Double(toDownload.count)
                    let depWeight = 1.0 / Double(toDownload.count)

                    self.downloadStatusText = "Downloading \(dep.name)... (\(dep.formattedSize))"

                    _ = try await downloader.download(dependency: dep) { [weak self] progress in
                        Task { @MainActor [weak self] in
                            let overall = depBaseProgress + (progress.fractionCompleted * depWeight)
                            self?.downloadProgress = overall
                            self?.downloadStatusText = "Downloading \(dep.name)... \(progress.formattedWrittenMB) / \(progress.formattedTotalMB) (\(progress.percentageString))"
                        }
                    }
                }

                // Explicit confirmation fulfilled: record installed dependencies in prefix manifest
                try pManager.recordInstalledDependencies(toDownload, for: profile.id)

                self.isDownloadingDependencies = false
                self.showDependencySheet = false
                self.downloadStatusText = "Installation complete."
                self.executeProcess()
            } catch {
                self.isDownloadingDependencies = false
                self.downloadErrorMessage = "Download failed: \(error.localizedDescription)"
                self.downloadStatusText = "Error during download."
            }
        }
    }

    public func cancelDependencyResolution() {
        dependencyDownloader.cancel()
        isDownloadingDependencies = false
        showDependencySheet = false
        logs += "\n[DependencyManager] Dependency installation cancelled by user. Launch aborted.\n"
    }

    private func executeProcess() {
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
                    self?.logs += "\n[!] Launch blocked by Anti-Cheat Sentinel:\n\(reason)\n"

                case .launched(_, let execResult, _, let retryAttempted, let altConfig):
                    self?.exitCode = execResult.exitCode
                    if retryAttempted, let alt = altConfig {
                        self?.logs += "\n[*] Automatic retry executed: \(alt)\n"
                    }
                    self?.logs += "\nProcess finished with exit code: \(execResult.exitCode)\n"

                case .profileNotFound(let id):
                    self?.logs += "\n[Error] Profile '\(id)' not found.\n"
                    self?.exitCode = 1

                case .executableNotFound(_, let paths, let suggestion):
                    self?.logs += "\n[Error] Executable not found in: \(paths.joined(separator: ", "))\n\(suggestion)\n"
                    self?.exitCode = 1

                case .runtimeMissing(let dep, let inst):
                    self?.logs += "\n[Error] Missing dependency: \(dep)\n\(inst)\n"
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
            logs += "\n[ProcessRunner] Cancellation requested by user in UI.\n"
        }
    }
}
