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
                    TextField("Buscar por título o ID...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .frame(maxWidth: 320)

                Picker("Filtro", selection: $viewModel.selectedFilter) {
                    ForEach(LibraryViewModel.CompatibilityFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 450)

                Spacer()

                Button(action: { viewModel.loadLibrary() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refrescar biblioteca y escaneo de Steam")
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.6))

            Divider()

            // Game items list
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.filteredItems) { item in
                        GameItemRow(item: item, onSelect: onSelectGame)
                    }

                    if viewModel.filteredItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("No se encontraron juegos que coincidan con el filtro.")
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

            CompatibilityBadge(status: item.compatibilityStatus)

            Button("Abrir en Lanzador") {
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
            return "Steam App ID: \(s.appId)"
        }
        return "Juego detectado"
    }
}
