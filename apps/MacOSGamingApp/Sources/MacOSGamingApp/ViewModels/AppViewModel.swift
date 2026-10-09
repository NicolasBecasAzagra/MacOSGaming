import Foundation
import Observation

@Observable
@MainActor
public final class AppViewModel {
    public enum NavigationTab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case library = "Library"
        case launcher = "Launcher"
        case diagnostics = "Diagnostics"
        case settings = "Settings"

        public var id: String { rawValue }

        public var systemImage: String {
            switch self {
            case .dashboard: return "gauge.with.needle"
            case .library: return "square.grid.2x2"
            case .launcher: return "play.circle"
            case .diagnostics: return "stethoscope"
            case .settings: return "gearshape"
            }
        }
    }

    public var selectedTab: NavigationTab = .dashboard
    public var selectedProfileId: String? = nil

    public init() {}

    public func navigateToLauncher(gameId: String) {
        self.selectedProfileId = gameId
        self.selectedTab = .launcher
    }
}
