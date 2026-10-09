import SwiftUI
import MacOSGamingCore

public struct LauncherView: View {
    @Bindable var viewModel: LaunchViewModel

    public init(viewModel: LaunchViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Game Header
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .frame(width: 64, height: 64)
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.selectedProfile?.name ?? viewModel.selectedGameId)
                            .font(.system(size: 22, weight: .bold))

                        HStack(spacing: 8) {
                            if let profile = viewModel.selectedProfile {
                                CompatibilityBadge(status: profile.compatibilityStatus)
                                Text("Backend: \(profile.recommendedRuntime.graphicsBackend.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Quick game selector picker
                    Picker("Juego", selection: $viewModel.selectedGameId) {
                        Text("Dota 2").tag("dota-2")
                        Text("Elden Ring").tag("elden-ring")
                        Text("Grand Theft Auto V").tag("gta-v")
                        Text("Counter-Strike 2").tag("cs2")
                        Text("Rocket League").tag("rocket-league")
                        Text("Valorant (Bloqueado)").tag("valorant")
                        Text("Fortnite (Bloqueado)").tag("fortnite")
                    }
                    .frame(width: 200)
                    .onChange(of: viewModel.selectedGameId) { _, newId in
                        viewModel.selectGame(gameId: newId)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .cornerRadius(12)

                // Sentinel Blocking Alert Banner
                if viewModel.wasBlockedBySentinel || (viewModel.selectedProfile?.antiCheat.type == .kernelRing0) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "shield.slash.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                            Text("EJECUCIÓN BLOQUEADA POR ANTI-CHEAT SENTINEL")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.red)
                        }

                        Text(viewModel.blockReason.isEmpty
                             ? "Este juego requiere un anti-cheat a nivel de kernel (Ring-0) incompatible con el kernel XNU de macOS. MacOSGaming bloquea estrictamente su ejecución local."
                             : viewModel.blockReason)
                            .font(.callout)

                        if !viewModel.alternatives.isEmpty {
                            Text("Alternativas legales y técnicas:")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            ForEach(viewModel.alternatives, id: \.self) { alt in
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.right.circle")
                                        .foregroundColor(.blue)
                                    Text(alt)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }

                // Configuration Panel
                VStack(alignment: .leading, spacing: 12) {
                    Text("PARÁMETROS DE LANZAMIENTO")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                        GridRow {
                            Toggle("Modo Dry-Run (Simulación)", isOn: $viewModel.isDryRun)
                                .help("Valida la configuración de sandbox y variables de entorno sin invocar el binario.")
                            Toggle("Reintento Automático en Fallo", isOn: $viewModel.autoRetry)
                                .help("Si la ejecución inicial falla, reintenta con configuración alternativa segura.")
                        }

                        GridRow {
                            Toggle("Consentimiento Modo Offline", isOn: $viewModel.offlineConsent)
                                .help("Requerido para juegos con anti-cheat multijugador que admiten campaña offline (ej. GTA V).")

                            HStack {
                                Text("Límite Timeout:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Slider(value: Binding(
                                    get: { viewModel.timeoutSeconds ?? 30.0 },
                                    set: { viewModel.timeoutSeconds = $0 }
                                ), in: 5...120, step: 5)
                                Text("\(Int(viewModel.timeoutSeconds ?? 30))s")
                                    .font(.caption.monospaced())
                                    .frame(width: 32)
                            }
                        }
                    }

                    HStack {
                        Text("Ruta ejecutable personalizada:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Dejar vacío para auto-detectar en Steam...", text: $viewModel.customPath)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .cornerRadius(12)

                // Action Bar
                HStack(spacing: 16) {
                    Button(action: { viewModel.launch() }) {
                        HStack {
                            if viewModel.isLaunching {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "play.fill")
                            }
                            Text(viewModel.isLaunching ? "Ejecutando..." : "Lanzar Juego")
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 140, minHeight: 28)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(viewModel.isLaunching || (viewModel.selectedProfile?.antiCheat.type == .kernelRing0))

                    if viewModel.isLaunching {
                        Button(action: { viewModel.cancel() }) {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Cancelar / Detener")
                                    .fontWeight(.semibold)
                            }
                            .frame(minWidth: 120, minHeight: 28)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }

                    Spacer()

                    if let code = viewModel.exitCode {
                        HStack(spacing: 6) {
                            Text("Código de salida:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(code)")
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(code == 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                .foregroundColor(code == 0 ? .green : .red)
                                .cornerRadius(4)
                        }
                    }
                }

                // Real-time Console Log Streaming
                VStack(alignment: .leading, spacing: 8) {
                    Text("REGISTROS DE EJECUCIÓN (STREAMING EN TIEMPO REAL)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    TerminalConsoleView(
                        text: viewModel.logs,
                        placeholder: "Haz clic en 'Lanzar Juego' para iniciar el proceso y visualizar los logs en tiempo real."
                    )
                }
            }
            .padding(20)
        }
    }
}
