import SwiftUI
import MacOSGamingCore

public struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings & Configuration")
                            .font(.system(size: 24, weight: .bold))
                        Text("Manage runtimes, library paths, and privacy preferences")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { viewModel.loadSettings() }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }

                // Section 1: Dependencies & Runtimes
                VStack(alignment: .leading, spacing: 12) {
                    Text("EXTERNAL RUNTIMES & DEPENDENCY STATUS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    VStack(spacing: 10) {
                        ForEach(viewModel.dependencies, id: \.name) { dep in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: dep.isInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(dep.isInstalled ? .green : .red)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(dep.name)
                                            .fontWeight(.semibold)
                                        Text("(\(dep.licenseType))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if let path = dep.installedPath {
                                        Text("Path: \(path)")
                                            .font(.caption.monospaced())
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text(dep.installationInstructions)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }

                                Spacer()

                                Link(destination: URL(string: dep.officialSourceURL) ?? URL(fileURLWithPath: "/")) {
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .help("Open official repository or documentation")
                            }
                            .padding(10)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                    .cornerRadius(12)
                }

                // Section 2: Library Paths
                VStack(alignment: .leading, spacing: 12) {
                    Text("SYSTEM PATHS & STORAGE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    VStack(spacing: 12) {
                        PathRow(
                            title: "Steam Library:",
                            description: "Root directory to scan for installed Steam games and ACF manifests",
                            path: viewModel.steamRootPath
                        )

                        Divider()

                        PathRow(
                            title: "Runtimes Directory:",
                            description: "Storage location for installed Wine-CX, DXMT, and DXVK runtimes",
                            path: viewModel.runtimesPath
                        )
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                    .cornerRadius(12)
                }

                // Section 3: Privacy & Telemetry
                VStack(alignment: .leading, spacing: 12) {
                    Text("PRIVACY & TELEMETRY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $viewModel.telemetryEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Anonymous Performance Telemetry Collection")
                                    .fontWeight(.medium)
                                Text("Disabled by default (OFF). If enabled, only sends aggregated benchmark statistics without personal identifiers or paths.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("Zero-Leakage Policy: MacOSGaming automatically sanitizes all user paths (/Users/... -> ~) and local account names from every benchmark report.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                    .cornerRadius(12)
                }
            }
            .padding(20)
        }
    }
}

private struct PathRow: View {
    let title: String
    let description: String
    let path: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(path)
                .font(.caption.monospaced())
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
        }
    }
}
