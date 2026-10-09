import SwiftUI
import MacOSGamingCore

public struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    let onNavigateToGame: (String) -> Void

    public init(viewModel: DashboardViewModel, onNavigateToGame: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onNavigateToGame = onNavigateToGame
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Control Dashboard")
                            .font(.system(size: 24, weight: .bold))
                        Text("Hardware telemetry and gaming readiness evaluation on Apple Silicon")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { viewModel.refreshDashboard() }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }

                if let report = viewModel.systemReport {
                    // Top stats row
                    HStack(alignment: .top, spacing: 16) {
                        ReadinessGaugeView(score: report.readinessScore)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("HARDWARE SPECIFICATIONS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)

                            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                                GridRow {
                                    Text("Processor:")
                                        .foregroundColor(.secondary)
                                    Text("\(report.chipModel) (\(report.cpuCores) CPU cores)")
                                        .fontWeight(.medium)
                                }
                                GridRow {
                                    Text("Unified Memory:")
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f GB RAM", report.unifiedMemoryGB))
                                        .fontWeight(.medium)
                                }
                                GridRow {
                                    Text("Metal GPU:")
                                        .foregroundColor(.secondary)
                                    Text(report.gpuName)
                                        .fontWeight(.medium)
                                }
                                GridRow {
                                    Text("Hardware Ray Tracing:")
                                        .foregroundColor(.secondary)
                                    Text(report.supportsHardwareRayTracing ? "Supported (M3/M4+)" : "Unsupported (M1/M2)")
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                        .cornerRadius(12)
                    }

                    // Software & Subsystems row
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SUBSYSTEMS & COMPATIBILITY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            StatusCard(
                                title: "Operating System",
                                value: "macOS \(report.osMarketingName) \(report.osVersion)",
                                icon: "desktopcomputer",
                                isPositive: report.osMajorVersion >= 14
                            )

                            StatusCard(
                                title: "Rosetta 2",
                                value: report.isRosettaInstalled ? "Installed & Active" : "Not Detected",
                                icon: "bolt.fill",
                                isPositive: report.isRosettaInstalled
                            )

                            StatusCard(
                                title: "AVX2 Support",
                                value: report.supportsAVX2 ? "Enabled (macOS 15+)" : "Requires macOS 15+",
                                icon: "cpu",
                                isPositive: report.supportsAVX2
                            )

                            StatusCard(
                                title: "Steam Games",
                                value: "\(viewModel.installedSteamGamesCount) installed",
                                icon: "gamecontroller.fill",
                                isPositive: viewModel.installedSteamGamesCount > 0
                            )
                        }
                    }

                    // Warnings or tips
                    if !report.isRosettaInstalled {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Rosetta 2 is not installed. To execute x86_64 Windows games, run in terminal: softwareupdate --install-rosetta")
                                .font(.callout)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(8)
                    }

                    if !report.supportsAVX2 {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("For modern games requiring AVX/AVX2 vector instructions, updating to macOS 15.0 Sequoia or later is recommended.")
                                .font(.callout)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(8)
                    }

                    // Quick access shortcuts
                    VStack(alignment: .leading, spacing: 10) {
                        Text("QUICK SHORTCUTS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            QuickLaunchButton(title: "Dota 2 (Native)", gameId: "dota-2", onNavigate: onNavigateToGame)
                            QuickLaunchButton(title: "Elden Ring (DXMT)", gameId: "elden-ring", onNavigate: onNavigateToGame)
                            QuickLaunchButton(title: "Grand Theft Auto V", gameId: "gta-v", onNavigate: onNavigateToGame)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

private struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let isPositive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isPositive ? .green : .secondary)
                Spacer()
                Circle()
                    .fill(isPositive ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
            }
            Spacer()
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 85, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(10)
    }
}

private struct QuickLaunchButton: View {
    let title: String
    let gameId: String
    let onNavigate: (String) -> Void

    var body: some View {
        Button(action: { onNavigate(gameId) }) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.blue)
                Text(title)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
