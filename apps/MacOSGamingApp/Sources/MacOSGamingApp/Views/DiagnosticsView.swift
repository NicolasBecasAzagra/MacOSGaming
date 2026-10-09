import SwiftUI
import MacOSGamingCore

public struct DiagnosticsView: View {
    @Bindable var viewModel: DiagnosticsViewModel

    public init(viewModel: DiagnosticsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Diagnósticos e Inspector del Sistema")
                            .font(.system(size: 24, weight: .bold))
                        Text("Ejecución de System Doctor y validación de rendimiento para juegos reales")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { viewModel.runDoctor() }) {
                        Label("Re-ejecutar Doctor", systemImage: "arrow.clockwise")
                    }
                }

                // Section 1: System Doctor Report
                VStack(alignment: .leading, spacing: 12) {
                    Text("INFORME DEL SYSTEM DOCTOR")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    if let report = viewModel.systemReport {
                        VStack(spacing: 10) {
                            DoctorMetricRow(label: "Chip Apple Silicon", value: report.chipModel, status: .ok)
                            DoctorMetricRow(label: "Núcleos CPU", value: "\(report.cpuCores) núcleos", status: .ok)
                            DoctorMetricRow(label: "Memoria Unificada", value: String(format: "%.1f GB", report.unifiedMemoryGB), status: report.unifiedMemoryGB >= 16 ? .ok : .warning)
                            DoctorMetricRow(label: "Acelerador Gráfico Metal", value: report.gpuName, status: .ok)
                            DoctorMetricRow(label: "Ray Tracing por Hardware", value: report.supportsHardwareRayTracing ? "Compatible" : "No disponible", status: report.supportsHardwareRayTracing ? .ok : .neutral)
                            DoctorMetricRow(label: "Versión de macOS", value: "macOS \(report.osMarketingName) \(report.osVersion)", status: report.osMajorVersion >= 14 ? .ok : .warning)
                            DoctorMetricRow(label: "Traducción Rosetta 2", value: report.isRosettaInstalled ? "Instalado y activo" : "No instalado", status: report.isRosettaInstalled ? .ok : .error)
                            DoctorMetricRow(label: "Instrucciones AVX2 en Rosetta", value: report.supportsAVX2 ? "Habilitado" : "Incompatible (< macOS 15)", status: report.supportsAVX2 ? .ok : .warning)
                            DoctorMetricRow(label: "Espacio Libre en Disco", value: String(format: "%.1f GB", report.freeDiskSpaceGB), status: report.freeDiskSpaceGB >= 50 ? .ok : .warning)
                            DoctorMetricRow(label: "Gaming Readiness Score", value: "\(report.readinessScore) / 100", status: report.readinessScore >= 60 ? .ok : .warning)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                        .cornerRadius(12)
                    }
                }

                // Section 2: Real-Game Validation Benchmark Runner
                VStack(alignment: .leading, spacing: 12) {
                    Text("VALIDACIÓN Y BENCHMARKING DE JUEGOS REALES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 16) {
                            Picker("Juego a Validar:", selection: $viewModel.validationGameId) {
                                Text("Dota 2 (Nativo Metal)").tag("dota-2")
                                Text("Elden Ring (DXMT)").tag("elden-ring")
                                Text("Grand Theft Auto V").tag("gta-v")
                                Text("Counter-Strike 2").tag("cs2")
                                Text("Rocket League").tag("rocket-league")
                                Text("Valorant (Sentinel Gate)").tag("valorant")
                            }
                            .frame(width: 250)

                            Button(action: { viewModel.runValidation(dryRun: true) }) {
                                HStack {
                                    if viewModel.isValidating {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Image(systemName: "checkmark.shield.fill")
                                    }
                                    Text(viewModel.isValidating ? "Validando..." : "Validar (Dry-Run)")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .disabled(viewModel.isValidating)

                            Button("Validar Proceso Real") {
                                viewModel.runValidation(dryRun: false)
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.isValidating)
                        }

                        if let report = viewModel.latestReport {
                            // Validation result summary card
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: report.wasCleanExit ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(report.wasCleanExit ? .green : .orange)
                                    Text("Informe de Validación: \(report.gameName)")
                                        .font(.headline)
                                    Spacer()
                                    Text(report.timestampISO8601)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Divider()

                                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
                                    GridRow {
                                        Text("Estado de Ejecución:").foregroundColor(.secondary)
                                        Text(report.wasCleanExit ? "Completado con Éxito" : "Código de Salida: \(report.exitCode)").fontWeight(.semibold)
                                    }
                                    GridRow {
                                        Text("Tiempo de Arranque:").foregroundColor(.secondary)
                                        Text(String(format: "%.1f ms", report.startupTimeMs)).fontWeight(.semibold)
                                    }
                                    GridRow {
                                        Text("Tasa de Cuadros (FPS):").foregroundColor(.secondary)
                                        Text(report.estimatedFPS).fontWeight(.semibold)
                                    }
                                    GridRow {
                                        Text("Sandbox Prefijo (Sanitizado):").foregroundColor(.secondary)
                                        Text(report.prefixPathSanitized).font(.caption.monospaced())
                                    }
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                        }

                        TerminalConsoleView(
                            text: viewModel.validationOutput,
                            placeholder: "Haz clic en 'Validar' para ejecutar la suite de comprobación y ver los logs."
                        )
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

private enum MetricStatus {
    case ok, warning, error, neutral
}

private struct DoctorMetricRow: View {
    let label: String
    let value: String
    let status: MetricStatus

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
        .font(.system(size: 13))
    }

    private var statusColor: Color {
        switch status {
        case .ok: return .green
        case .warning: return .orange
        case .error: return .red
        case .neutral: return .gray
        }
    }
}
