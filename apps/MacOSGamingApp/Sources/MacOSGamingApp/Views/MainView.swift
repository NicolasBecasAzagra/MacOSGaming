import SwiftUI

public struct MainView: View {
    @State private var appViewModel = AppViewModel()
    @State private var dashboardViewModel = DashboardViewModel()
    @State private var libraryViewModel = LibraryViewModel()
    @State private var launchViewModel = LaunchViewModel()
    @State private var diagnosticsViewModel = DiagnosticsViewModel()
    @State private var settingsViewModel = SettingsViewModel()

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(AppViewModel.NavigationTab.allCases, selection: $appViewModel.selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.systemImage)
                }
            }
            .navigationTitle("MacOSGaming")
            .listStyle(.sidebar)
            .frame(minWidth: 190)
        } detail: {
            Group {
                switch appViewModel.selectedTab {
                case .dashboard:
                    DashboardView(
                        viewModel: dashboardViewModel,
                        onNavigateToGame: { gameId in
                            launchViewModel.selectGame(gameId: gameId)
                            appViewModel.selectedTab = .launcher
                        }
                    )
                case .library:
                    LibraryView(
                        viewModel: libraryViewModel,
                        onSelectGame: { gameId in
                            launchViewModel.selectGame(gameId: gameId)
                            appViewModel.selectedTab = .launcher
                        }
                    )
                case .launcher:
                    LauncherView(viewModel: launchViewModel)
                case .diagnostics:
                    DiagnosticsView(viewModel: diagnosticsViewModel)
                case .settings:
                    SettingsView(viewModel: settingsViewModel)
                }
            }
            .frame(minWidth: 650, minHeight: 520)
        }
    }
}
