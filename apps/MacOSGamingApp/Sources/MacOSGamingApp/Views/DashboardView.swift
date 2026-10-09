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
                        Text("Panel de Control del Sistema")
                            .font(.system(size: 24, weight: .bold))
                        Text("Diagnóstico de hardware y preparación para gaming en Apple Silicon")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { viewModel.refreshDashboard() }) {
                        Label("Actualizar", systemImage: "arrow.clockwise")
                    }
                }

                if let report = viewModel.systemReport {
                    // Top stats row
                    HStack(alignment: .top, spacing: 16) {
                        ReadinessGaugeView(score: report.readinessScore)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("ESPECIFICACIONES DE HARDWARE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)

                            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                                GridRow {
                                    Text("Procesador:")
                                        .foregroundColor(.secondary)
                                    Text("\(report.chipModel) (\(report.cpuCores) núcleos CPU)")
                                        .fontWeight(.medium)
                                }
                                GridRow {
                                    Text("Memoria Unificada:")
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f GB RAM", report.unifiedMemoryGB))
                                        .fontWeight(.medium)
                                }
                                GridRow {
                                    Text("GPU Metal:")
                                        .foregroundColor(.secondary)
                                    Text(report.gpuName)
                                        .fontWeight(.medium)
                                }
                                GridRow {
                                    Text("Ray Tracing Hardware:")
                                        .foregroundColor(.secondary)
                                    Text(report.supportsHardwareRayTracing ? "Compatible (M3/M4+)" : "No compatible (M1/M2 o emulado)")
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
                        Text("SUBSISTEMAS Y COMPATIBILIDAD")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            StatusCard(
                                title: "Sistema Operativo",
                                value: "macOS \(report.osMarketingName) \(report.osVersion)",
                                icon: "desktopcomputer",
                                isPositive: report.osMajorVersion >= 14
                            )

                            StatusCard(
                                title: "Rosetta 2",
                                value: report.isRosettaInstalled ? "Instalado y Activo" : "No detectado",
                                icon: "bolt.fill",
                                isPositive: report.isRosettaInstalled
                            )

                            StatusCard(
                                title: "Soporte AVX2",
                                value: report.supportsAVX2 ? "Habilitado (macOS 15+)" : "Requiere macOS 15+",
                                icon: "cpu",
                                isPositive: report.supportsAVX2
                            )

                            StatusCard(
                                title: "Juegos en Steam",
                                value: "\(viewModel.installedSteamGamesCount) instalados",
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
                            Text("Rosetta 2 no está instalado. Para ejecutar juegos de Windows x86_64, ejecuta en terminal: softwareupdate --install-rosetta")
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
                            Text("Para juegos modernos con instrucciones AVX/AVX2, se requiere actualizar a macOS 15.0 Sequoia o posterior.")
                                .font(.callout)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(8)
                    }

                    // Quick access shortcuts
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ACCESOS RÁPIDOS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            QuickLaunchButton(title: "Dota 2 (Nativo)", gameId: "dota-2", onNavigate: onNavigateToGame)
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
