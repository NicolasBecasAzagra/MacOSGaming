import Foundation
import Observation
import MacOSGamingCore

@Observable
@MainActor
public final class DashboardViewModel {
    private let systemDetector: SystemDetector
    private let steamDetector: SteamLibraryDetector

    public var systemReport: SystemReport?
    public var isLoading: Bool = false
    public var installedSteamGamesCount: Int = 0

    public init(
        systemDetector: SystemDetector = SystemDetector(),
        steamDetector: SteamLibraryDetector = SteamLibraryDetector()
    ) {
        self.systemDetector = systemDetector
        self.steamDetector = steamDetector
        refreshDashboard()
    }

    public func refreshDashboard() {
        isLoading = true
        defer { isLoading = false }
        self.systemReport = systemDetector.detect()
        self.installedSteamGamesCount = steamDetector.detectInstalledApps().count
    }
}
