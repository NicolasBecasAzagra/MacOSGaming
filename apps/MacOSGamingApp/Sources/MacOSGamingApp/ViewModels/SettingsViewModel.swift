import Foundation
import Observation
import MacOSGamingCore

@Observable
@MainActor
public final class SettingsViewModel {
    private let dependencyManager: DependencyManager
    private let steamDetector: SteamLibraryDetector

    public var dependencies: [DependencyInfo] = []
    public var steamRootPath: String = ""
    public var runtimesPath: String = ""
    public var telemetryEnabled: Bool = false // Desactivada por defecto
    public var defaultTimeoutSeconds: Double = 30.0

    public init(
        dependencyManager: DependencyManager = DependencyManager(),
        steamDetector: SteamLibraryDetector = SteamLibraryDetector()
    ) {
        self.dependencyManager = dependencyManager
        self.steamDetector = steamDetector
        self.steamRootPath = steamDetector.steamRootDirectory.path
        self.runtimesPath = dependencyManager.runtimesDirectory.path
        loadSettings()
    }

    public func loadSettings() {
        self.dependencies = dependencyManager.checkDependencies()
        self.steamRootPath = steamDetector.steamRootDirectory.path
        self.runtimesPath = dependencyManager.runtimesDirectory.path
    }
}
