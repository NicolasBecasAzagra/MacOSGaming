import Foundation

public enum LaunchDecision: Sendable, Equatable {
    case permitted(
        profile: GameProfile,
        environmentVariables: [String: String],
        graphicsBackend: GraphicsBackend
    )
    case offlineOnly(
        profile: GameProfile,
        notice: String,
        requiredArguments: [String],
        environmentVariables: [String: String]
    )
    case blocked(
        profile: GameProfile,
        reason: String,
        alternatives: [String]
    )
}

public struct AntiCheatSentinel: Sendable {
    public init() {}

    public func evaluate(profile: GameProfile, userConsentOffline: Bool = false) -> LaunchDecision {
        switch profile.launchPolicy {
        case .blockKernelAnticheat:
            let reason = profile.policyNotice
            let alternatives = [
                "Dedicated physical Windows PC with hardware TPM 2.0 and UEFI Secure Boot",
                "Official cloud game streaming (NVIDIA GeForce NOW or Xbox Cloud Gaming) if available for this title"
            ]
            return .blocked(
                profile: profile,
                reason: reason,
                alternatives: alternatives
            )

        case .allowOfflineOnly:
            if userConsentOffline {
                var args: [String] = []
                if profile.id == "gta-v" {
                    args.append("-nobattleye")
                }
                return .offlineOnly(
                    profile: profile,
                    notice: "Launching in verified offline single-player mode. Online multiplayer is disabled because \(profile.antiCheat.name) is not supported under macOS.",
                    requiredArguments: args,
                    environmentVariables: profile.recommendedRuntime.environmentVariables
                )
            } else {
                return .blocked(
                    profile: profile,
                    reason: "\(profile.name) online multiplayer requires \(profile.antiCheat.name), which cannot run under macOS compatibility layers. Offline single-player mode is available if specifically requested.",
                    alternatives: [
                        "Launch in offline single-player mode (pass '--offline' flag)",
                        "Play online multiplayer on a native Windows PC or official cloud gaming service"
                    ]
                )
            }

        case .allowDirect:
            return .permitted(
                profile: profile,
                environmentVariables: profile.recommendedRuntime.environmentVariables,
                graphicsBackend: profile.recommendedRuntime.graphicsBackend
            )
        }
    }
}
