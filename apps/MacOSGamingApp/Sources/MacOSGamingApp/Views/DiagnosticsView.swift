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
                        Text("System Diagnostics & Inspector")
                            .font(.system(size: 24, weight: .bold))
                        Text("Run System Doctor inspections and performance validation for real games")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { viewModel.runDoctor() }) {
                        Label("Re-run Doctor", systemImage: "arrow.clockwise")
                    }
                }

                // Section 1: System Doctor Report
                VStack(alignment: .leading, spacing: 12) {
                    Text("SYSTEM DOCTOR REPORT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    if let report = viewModel.systemReport {
                        VStack(spacing: 10) {
                            DoctorMetricRow(label: "Apple Silicon Chip", value: report.chipModel, status: .ok)
                            DoctorMetricRow(label: "CPU Cores", value: "\(report.cpuCores) cores", status: .ok)
                            DoctorMetricRow(label: "Unified Memory", value: String(format: "%.1f GB", report.unifiedMemoryGB), status: report.unifiedMemoryGB >= 16 ? .ok : .warning)
                            DoctorMetricRow(label: "Metal Graphics Accelerator", value: report.gpuName, status: .ok)
                            DoctorMetricRow(label: "Hardware Ray Tracing", value: report.supportsHardwareRayTracing ? "Supported" : "Not Available", status: report.supportsHardwareRayTracing ? .ok : .neutral)
                            DoctorMetricRow(label: "macOS Version", value: "macOS \(report.osMarketingName) \(report.osVersion)", status: report.osMajorVersion >= 14 ? .ok : .warning)
                            DoctorMetricRow(label: "Rosetta 2 Translation", value: report.isRosettaInstalled ? "Installed & Active" : "Not Installed", status: report.isRosettaInstalled ? .ok : .error)
                            DoctorMetricRow(label: "Rosetta AVX2 Support", value: report.supportsAVX2 ? "Enabled" : "Incompatible (< macOS 15)", status: report.supportsAVX2 ? .ok : .warning)
                            DoctorMetricRow(label: "Free Disk Space", value: String(format: "%.1f GB", report.freeDiskSpaceGB), status: report.freeDiskSpaceGB >= 50 ? .ok : .warning)
                            DoctorMetricRow(label: "Gaming Readiness Score", value: "\(report.readinessScore) / 100", status: report.readinessScore >= 60 ? .ok : .warning)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                        .cornerRadius(12)
                    }
                }

                // Section 2: Real-Game Validation Benchmark Runner
                VStack(alignment: .leading, spacing: 12) {
                    Text("REAL GAME VALIDATION & BENCHMARKING")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 16) {
                            Picker("Game to Validate:", selection: $viewModel.validationGameId) {
                                Text("Dota 2 (Native Metal)").tag("dota-2")
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
                                    Text(viewModel.isValidating ? "Validating..." : "Validate (Dry-Run)")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .disabled(viewModel.isValidating)

                            Button("Validate Real Process") {
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
                                    Text("Validation Report: \(report.gameName)")
                                        .font(.headline)
                                    Spacer()
                                    Text(report.timestampISO8601)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Divider()

                                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
                                    GridRow {
                                        Text("Execution Status:").foregroundColor(.secondary)
                                        Text(report.wasCleanExit ? "Completed Successfully" : "Exit Code: \(report.exitCode)").fontWeight(.semibold)
                                    }
                                    GridRow {
                                        Text("Startup Initialization Time:").foregroundColor(.secondary)
                                        Text(String(format: "%.1f ms", report.startupTimeMs)).fontWeight(.semibold)
                                    }
                                    GridRow {
                                        Text("Framerate (FPS):").foregroundColor(.secondary)
                                        Text(report.estimatedFPS).fontWeight(.semibold)
                                    }
                                    GridRow {
                                        Text("Prefix Sandbox (Sanitized):").foregroundColor(.secondary)
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
                            placeholder: "Click 'Validate' to execute the test suite and view streaming logs."
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
