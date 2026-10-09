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

    public func profile(forSteamAppId appId: Int) -> GameProfile? {
        lock.lock()
        defer { lock.unlock() }
        return profiles.values.first { $0.steamAppId == appId }
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
            steamAppId: nil,
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
                "https://en.wikipedia.org/wiki/Valorant",
                "https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment"
            ]
        ),
        GameProfile(
            id: "league-of-legends",
            name: "League of Legends",
            publisher: "Riot Games",
            steamAppId: nil,
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
                "https://en.wikipedia.org/wiki/League_of_Legends",
                "https://developer.apple.com/metal/"
            ]
        ),
        GameProfile(
            id: "cs2",
            name: "Counter-Strike 2",
            publisher: "Valve Corporation",
            steamAppId: 730,
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
                "https://store.steampowered.com/app/730/CounterStrike_2/",
                "https://en.wikipedia.org/wiki/Counter-Strike_2"
            ]
        ),
        GameProfile(
            id: "dota-2",
            name: "Dota 2",
            publisher: "Valve Corporation",
            steamAppId: 570,
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
                "https://store.steampowered.com/app/570/Dota_2/",
                "https://github.com/KhronosGroup/MoltenVK"
            ]
        ),
        GameProfile(
            id: "elden-ring",
            name: "Elden Ring",
            publisher: "FromSoftware / Bandai Namco",
            steamAppId: 1245620,
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
                "https://store.steampowered.com/app/1245620/ELDEN_RING/",
                "https://developer.apple.com/games/"
            ]
        ),
        GameProfile(
            id: "gta-v",
            name: "Grand Theft Auto V",
            publisher: "Rockstar Games",
            steamAppId: 271590,
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
                "https://store.steampowered.com/app/271590/Grand_Theft_Auto_V/",
                "https://github.com/3Shain/dxmt"
            ]
        ),
        GameProfile(
            id: "rocket-league",
            name: "Rocket League",
            publisher: "Psyonix / Epic Games",
            steamAppId: 252950,
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
                "https://store.steampowered.com/app/252950/Rocket_League/",
                "https://en.wikipedia.org/wiki/Rocket_League"
            ]
        ),
        GameProfile(
            id: "fortnite",
            name: "Fortnite",
            publisher: "Epic Games",
            steamAppId: nil,
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
                "https://en.wikipedia.org/wiki/Fortnite",
                "https://en.wikipedia.org/wiki/Easy_Anti-Cheat"
            ]
        )
    ]
}
