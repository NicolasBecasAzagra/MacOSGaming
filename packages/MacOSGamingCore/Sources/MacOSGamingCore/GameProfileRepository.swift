import Foundation

public final class GameProfileRepository: @unchecked Sendable {
    private var profiles: [String: GameProfile] = [:]
    private let lock = NSLock()

    public init(customDirectory: URL? = nil) {
        loadProfiles(from: customDirectory)
    }

    public func loadProfiles(from directory: URL? = nil) {
        lock.lock()
        defer { lock.unlock() }

        profiles.removeAll()

        // 1. Try loading from directory if provided, or from current working directory 'data/profiles'
        let targetDir: URL
        if let directory = directory {
            targetDir = directory
        } else {
            let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            targetDir = cwd.appendingPathComponent("data/profiles")
        }

        if FileManager.default.fileExists(atPath: targetDir.path) {
            loadFromDisk(directory: targetDir)
        }

        // 2. Ensure default target profiles exist (fallback)
        for profile in Self.embeddedProfiles {
            if profiles[profile.id] == nil {
                profiles[profile.id] = profile
            }
        }
    }

    private func loadFromDisk(directory: URL) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return
        }

        let decoder = JSONDecoder()
        for file in files where file.pathExtension == "json" && file.lastPathComponent != "schema.json" {
            guard let data = try? Data(contentsOf: file),
                  let profile = try? decoder.decode(GameProfile.self, from: data) else {
                continue
            }
            profiles[profile.id] = profile
        }
    }

    public func profile(for id: String) -> GameProfile? {
        lock.lock()
        defer { lock.unlock() }
        return profiles[id.lowercased()]
    }

    public func allProfiles() -> [GameProfile] {
        lock.lock()
        defer { lock.unlock() }
        return Array(profiles.values).sorted { $0.name < $1.name }
    }

    public static let embeddedProfiles: [GameProfile] = [
        GameProfile(
            id: "valorant",
            name: "Valorant",
            publisher: "Riot Games",
            compatibilityStatus: .notSupported,
            confidenceLevel: .verified,
            lastVerified: "2026-10-09",
            antiCheat: AntiCheatInfo(
                name: "Riot Vanguard",
                type: .kernelRing0,
                supportedOnMacOS: false,
                offlineModeAllowed: false
            ),
            launchPolicy: .blockKernelAnticheat,
            policyNotice: "Valorant requires the kernel-level anti-cheat Riot Vanguard (vgk.sys), TPM 2.0, Secure Boot, and physical x86 Windows. It cannot run in Wine or virtual machines. MacOSGaming strictly blocks launching this game locally. Please use a physical Windows PC.",
            recommendedRuntime: RecommendedRuntime(graphicsBackend: .d3dmetalUserProvided, environmentVariables: [:]),
            sources: [
                "Riot Games Support: Vanguard Architecture and System Requirements (2024-2026)",
                "Apple Developer: Rosetta 2 and Darwin Kernel Architecture (User Mode vs Ring 0)"
            ]
        ),
        GameProfile(
            id: "league-of-legends",
            name: "League of Legends",
            publisher: "Riot Games",
            compatibilityStatus: .nativeMacOS,
            confidenceLevel: .verified,
            lastVerified: "2026-10-09",
            antiCheat: AntiCheatInfo(
                name: "Riot Vanguard (Windows Only)",
                type: .none,
                supportedOnMacOS: true,
                offlineModeAllowed: true
            ),
            launchPolicy: .allowDirect,
            policyNotice: "League of Legends provides an official native macOS client maintained by Riot Games. While Windows requires Vanguard (since Patch 14.9), the macOS client is officially exempt and runs directly via Metal.",
            recommendedRuntime: RecommendedRuntime(graphicsBackend: .metalNative, environmentVariables: [:]),
            sources: [
                "Riot Games Support Bulletin: Patch 14.9 Release Notes & macOS Vanguard Exemption Policy (May 2024)",
                "Riot Games: Official League of Legends macOS Installer"
            ]
        ),
        GameProfile(
            id: "cs2",
            name: "Counter-Strike 2",
            publisher: "Valve Corporation",
            compatibilityStatus: .likelyCompatible,
            confidenceLevel: .verified,
            lastVerified: "2026-10-09",
            antiCheat: AntiCheatInfo(
                name: "Valve Anti-Cheat (VAC)",
                type: .userspace,
                supportedOnMacOS: false,
                offlineModeAllowed: true
            ),
            launchPolicy: .allowDirect,
            policyNotice: "Valve officially confirmed that Counter-Strike 2 will NOT be released on macOS (FAQ Oct 2023). It executes via compatibility layers (CrossOver/GPTK). Multiplayer matchmaking with VAC experiences frequent session authentication drops ('VAC was unable to verify your game session'); permanent ban risk under Wine remains officially unverified.",
            recommendedRuntime: RecommendedRuntime(
                graphicsBackend: .d3dmetalUserProvided,
                environmentVariables: [
                    "WINEMSYNC": "1",
                    "ROSETTA_ADVERTISE_AVX": "1"
                ]
            ),
            sources: [
                "Valve Steam Support: Counter-Strike 2 macOS Deprecation Notice (October 2023)",
                "IGN: Counter-Strike 2 Drops Mac Support (October 2023)",
                "MacRumors: Valve Drops Support for Counter-Strike 2 on Mac (October 2023)"
            ]
        ),
        GameProfile(
            id: "dota-2",
            name: "Dota 2",
            publisher: "Valve Corporation",
            compatibilityStatus: .nativeMacOS,
            confidenceLevel: .verified,
            lastVerified: "2026-10-09",
            antiCheat: AntiCheatInfo(
                name: "Valve Anti-Cheat (VAC Native)",
                type: .none,
                supportedOnMacOS: true,
                offlineModeAllowed: true
            ),
            launchPolicy: .allowDirect,
            policyNotice: "Dota 2 is officially supported natively on macOS through Steam, utilizing MoltenVK for Vulkan-to-Metal translation and running seamlessly on Apple Silicon via Rosetta 2.",
            recommendedRuntime: RecommendedRuntime(graphicsBackend: .metalNative, environmentVariables: [:]),
            sources: [
                "Valve Steam Store: Dota 2 Mac System Requirements",
                "MoltenVK Project: Valve Source 2 Engine Integration Notes"
            ]
        ),
        GameProfile(
            id: "elden-ring",
            name: "Elden Ring",
            publisher: "FromSoftware / Bandai Namco",
            compatibilityStatus: .likelyCompatible,
            confidenceLevel: .verified,
            lastVerified: "2026-10-09",
            antiCheat: AntiCheatInfo(
                name: "Easy Anti-Cheat (EAC)",
                type: .kernelRing0,
                supportedOnMacOS: false,
                offlineModeAllowed: true
            ),
            launchPolicy: .allowOfflineOnly,
            policyNotice: "Elden Ring renders smoothly via D3DMetal (DirectX 12). Easy Anti-Cheat (EAC) fails on macOS Wine, preventing online multiplayer connectivity. The game must be launched in offline single-player mode.",
            recommendedRuntime: RecommendedRuntime(
                graphicsBackend: .d3dmetalUserProvided,
                environmentVariables: ["WINEMSYNC": "1"]
            ),
            sources: [
                "FromSoftware / Bandai Namco: Elden Ring Steam System Requirements",
                "Apple Developer: Game Porting Toolkit Evaluation Guidelines"
            ]
        ),
        GameProfile(
            id: "gta-v",
            name: "Grand Theft Auto V",
            publisher: "Rockstar Games",
            compatibilityStatus: .likelyCompatible,
            confidenceLevel: .verified,
            lastVerified: "2026-10-09",
            antiCheat: AntiCheatInfo(
                name: "BattlEye",
                type: .kernelRing0,
                supportedOnMacOS: false,
                offlineModeAllowed: true
            ),
            launchPolicy: .allowOfflineOnly,
            policyNotice: "Rockstar integrated BattlEye into GTA V in September 2024. Story Mode is 100% playable by passing '-nobattleye'. Official GTA Online multiplayer servers require the BattlEye kernel driver and are blocked under Wine.",
            recommendedRuntime: RecommendedRuntime(
                graphicsBackend: .dxmt,
                environmentVariables: ["WINEMSYNC": "1"]
            ),
            sources: [
                "Rockstar Support Bulletin: BattlEye Integration in Grand Theft Auto V (September 2024)",
                "DXMT Project: Direct3D 11 compatibility notes with RAGE engine"
            ]
        ),
        GameProfile(
            id: "rocket-league",
            name: "Rocket League",
            publisher: "Psyonix / Epic Games",
            compatibilityStatus: .requiresWindows,
            confidenceLevel: .verified,
            lastVerified: "2026-10-09",
            antiCheat: AntiCheatInfo(
                name: "Easy Anti-Cheat (EAC)",
                type: .kernelRing0,
                supportedOnMacOS: false,
                offlineModeAllowed: true
            ),
            launchPolicy: .allowOfflineOnly,
            policyNotice: "Psyonix dropped native macOS support in 2020 and added Easy Anti-Cheat (EAC) in April 2024. While local matches and offline training function under Wine/DXMT, online multiplayer queues reject Wine clients. Full online play requires Windows or cloud gaming.",
            recommendedRuntime: RecommendedRuntime(
                graphicsBackend: .dxmt,
                environmentVariables: ["WINEMSYNC": "1"]
            ),
            sources: [
                "Psyonix Support: Rocket League Easy Anti-Cheat Integration (April 2024)",
                "Psyonix: macOS and Linux Support Deprecation Bulletin (March 2020)"
            ]
        ),
        GameProfile(
            id: "fortnite",
            name: "Fortnite",
            publisher: "Epic Games",
            compatibilityStatus: .notSupported,
            confidenceLevel: .verified,
            lastVerified: "2026-10-09",
            antiCheat: AntiCheatInfo(
                name: "BattlEye / Easy Anti-Cheat",
                type: .kernelRing0,
                supportedOnMacOS: false,
                offlineModeAllowed: false
            ),
            launchPolicy: .blockKernelAnticheat,
            policyNotice: "Fortnite employs kernel-level anti-cheat (BattlEye & Easy Anti-Cheat) on Windows. The native Mac version has been frozen at Chapter 2 Season 3 (2020) and cannot connect to current season servers. The Windows version cannot run in Wine or virtual machines. Cloud gaming (GeForce NOW or Xbox Cloud Gaming) is required on Mac.",
            recommendedRuntime: RecommendedRuntime(graphicsBackend: .dxmt, environmentVariables: [:]),
            sources: [
                "Epic Games Support: Fortnite on Mac Status and Cloud Alternatives",
                "Epic Games: Anti-Cheat System Integration Bulletins"
            ]
        )
    ]
}
