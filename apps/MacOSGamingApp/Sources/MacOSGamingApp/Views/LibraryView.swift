import SwiftUI
import MacOSGamingCore

public struct LibraryView: View {
    @Bindable var viewModel: LibraryViewModel
    let onSelectGame: (String) -> Void

    public init(viewModel: LibraryViewModel, onSelectGame: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onSelectGame = onSelectGame
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Filter and Search Toolbar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search by title or ID...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .frame(maxWidth: 280)

                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(LibraryViewModel.CompatibilityFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 500)

                Spacer()

                Button(action: { viewModel.loadLibrary() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh library and Steam scan")
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.6))

            Divider()

            // Game items list
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.filteredItems) { item in
                        GameItemRow(item: item, viewModel: viewModel, onSelect: onSelectGame)
                    }

                    if viewModel.filteredItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("No games found matching the selected filter.")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(60)
                    }
                }
                .padding(16)
            }
        }
    }
}

private struct GameItemRow: View {
    let item: DisplayGameItem
    let viewModel: LibraryViewModel
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 44, height: 44)
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .bold))
                    if item.isInstalledInSteam {
                        Text("STEAM")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.18))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // State & Compatibility Badges
            ProfileStateBadge(state: item.profileState)

            if item.isOptimized {
                CompatibilityBadge(status: item.compatibilityStatus)
            } else {
                // Unprofiled game: Button to request a new community profile
                Button(action: {
                    let url = viewModel.profileRequestURL(for: item)
                    NSWorkspace.shared.open(url)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 10))
                        Text("Request Profile")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Submit an issue on GitHub to request an optimized profile for this title.")
            }

            Button("Open in Launcher") {
                onSelect(item.profile?.id ?? item.id)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    private var subtitle: String {
        if let p = item.profile {
            return "ID: \(p.id) • Backend: \(p.recommendedRuntime.graphicsBackend.rawValue)"
        } else if let s = item.steamApp {
            return "Steam App ID: \(s.appId) • Unprofiled"
        }
        return "Detected game"
    }
}
