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
                    Picker("Game", selection: $viewModel.selectedGameId) {
                        Text("Dota 2").tag("dota-2")
                        Text("Elden Ring").tag("elden-ring")
                        Text("Grand Theft Auto V").tag("gta-v")
                        Text("Counter-Strike 2").tag("cs2")
                        Text("Rocket League").tag("rocket-league")
                        Text("Valorant (Blocked)").tag("valorant")
                        Text("Fortnite (Blocked)").tag("fortnite")
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
                            Text("EXECUTION BLOCKED BY ANTI-CHEAT SENTINEL")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.red)
                        }

                        Text(viewModel.blockReason.isEmpty
                             ? "This title mandates a kernel-level (Ring-0) anti-cheat driver incompatible with the macOS XNU kernel. MacOSGaming strictly blocks local execution."
                             : viewModel.blockReason)
                            .font(.callout)

                        if !viewModel.alternatives.isEmpty {
                            Text("Legal and technical alternatives:")
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
                    Text("LAUNCH PARAMETERS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                        GridRow {
                            Toggle("Dry-Run Mode (Simulation)", isOn: $viewModel.isDryRun)
                                .help("Validates sandbox provisioning and environment variables without executing the game binary.")
                            Toggle("Auto-Retry on Failure", isOn: $viewModel.autoRetry)
                                .help("If initial execution fails, retries with fallback configuration.")
                        }

                        GridRow {
                            Toggle("Offline Mode Consent", isOn: $viewModel.offlineConsent)
                                .help("Required for games with multiplayer anti-cheat that officially permit offline campaign mode (e.g., GTA V).")

                            HStack {
                                Text("Timeout Limit:")
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
                        Text("Custom executable path:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Leave empty to auto-detect from Steam...", text: $viewModel.customPath)
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
                            Text(viewModel.isLaunching ? "Launching..." : "Launch Game")
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
                                Text("Cancel / Stop")
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
                            Text("Exit code:")
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
                    Text("EXECUTION LOGS (LIVE STREAMING)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

                    TerminalConsoleView(
                        text: viewModel.logs,
                        placeholder: "Click 'Launch Game' to start the process and stream real-time logs."
                    )
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $viewModel.showDependencySheet) {
            DependencyResolutionSheet(viewModel: viewModel)
        }
    }
}

public struct DependencyResolutionSheet: View {
    @Bindable var viewModel: LaunchViewModel

    public var body: some View {
        VStack(spacing: 0) {
            // Sheet Header
            HStack(spacing: 12) {
                Image(systemName: "shippingbox.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Required Runtimes & Dependencies")
                        .font(.headline)
                    Text("The following components are required to run \(viewModel.selectedProfile?.name ?? viewModel.selectedGameId). Explicit user confirmation is required prior to downloading.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))

            Divider()

            // List of missing dependencies
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.missingDependencies) { dep in
                        HStack(spacing: 12) {
                            Toggle("", isOn: Binding(
                                get: { viewModel.selectedDependencyIds.contains(dep.dependencyId) },
                                set: { _ in viewModel.toggleDependencySelection(dep.dependencyId) }
                            ))
                            .labelsHidden()
                            .disabled(viewModel.isDownloadingDependencies)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(dep.name)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(dep.category.rawValue)
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }

                                HStack(spacing: 12) {
                                    Text("Size: \(dep.formattedSize)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.primary)

                                    Text("•")
                                        .foregroundColor(.secondary)

                                    Link("Official Source: \(dep.officialSourceURL.host ?? "Website")", destination: dep.officialSourceURL)
                                        .font(.system(size: 11))

                                    Text("•")
                                        .foregroundColor(.secondary)

                                    Text(dep.licenseType)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
                .padding(16)
            }

            Divider()

            // Download Progress Bar & Status
            if viewModel.isDownloadingDependencies {
                VStack(spacing: 6) {
                    ProgressView(value: viewModel.downloadProgress, total: 1.0)
                        .progressViewStyle(.linear)
                    Text(viewModel.downloadStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))

                Divider()
            }

            if let errorMsg = viewModel.downloadErrorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMsg)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(8)
            }

            // Footer with Explicit Confirmation Action
            HStack {
                Text("Total to download: \(viewModel.formattedTotalSelectedSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Cancel") {
                    viewModel.cancelDependencyResolution()
                }
                .disabled(viewModel.isDownloadingDependencies)

                Button(action: {
                    viewModel.installSelectedDependencies()
                }) {
                    HStack(spacing: 6) {
                        if viewModel.isDownloadingDependencies {
                            ProgressView()
                                .controlSize(.small)
                            Text("Downloading...")
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Install Selected")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedDependencyIds.isEmpty || viewModel.isDownloadingDependencies)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
        }
        .frame(width: 580, height: 420)
    }
}
