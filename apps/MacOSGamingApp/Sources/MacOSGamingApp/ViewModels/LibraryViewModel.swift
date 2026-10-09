import Foundation
import Observation
import MacOSGamingCore

public enum ProfileState: String, Sendable, CaseIterable, Equatable {
    case optimized = "Optimized"
    case generic = "Generic"
}

public struct DisplayGameItem: Identifiable, Sendable {
    public var id: String { profile?.id ?? "steam-\(steamApp?.appId ?? 0)" }
    public let name: String
    public let steamApp: SteamInstalledApp?
    public let profile: GameProfile?
    public let compatibilityStatus: CompatibilityStatus
    public let isInstalledInSteam: Bool

    public var profileState: ProfileState {
        profile != nil ? .optimized : .generic
    }

    public var isOptimized: Bool {
        profileState == .optimized
    }

    public var isGeneric: Bool {
        profileState == .generic
    }

    public init(
        name: String,
        steamApp: SteamInstalledApp?,
        profile: GameProfile?,
        compatibilityStatus: CompatibilityStatus,
        isInstalledInSteam: Bool
    ) {
        self.name = name
        self.steamApp = steamApp
        self.profile = profile
        self.compatibilityStatus = compatibilityStatus
        self.isInstalledInSteam = isInstalledInSteam
    }
}

@Observable
@MainActor
public final class LibraryViewModel {
    private let profileRepository: GameProfileRepository
    private let steamDetector: SteamLibraryDetector

    public var items: [DisplayGameItem] = []
    public var searchQuery: String = ""
    public var selectedFilter: CompatibilityFilter = .all

    public enum CompatibilityFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case optimized = "Optimized"
        case generic = "Generic"
        case native = "Native"
        case compatible = "Compatible"
        case offlineOnly = "Offline Only"
        case blocked = "Blocked"

        public var id: String { rawValue }
    }

    public init(
        profileRepository: GameProfileRepository = GameProfileRepository(),
        steamDetector: SteamLibraryDetector = SteamLibraryDetector()
    ) {
        self.profileRepository = profileRepository
        self.steamDetector = steamDetector
        loadLibrary()
    }

    public func loadLibrary() {
        let profiles = profileRepository.allProfiles()
        let steamApps = steamDetector.detectInstalledApps()

        var combined: [DisplayGameItem] = []

        // 1. Add all profiled games, linking Steam installation if detected
        for p in profiles {
            let matchedSteam = steamApps.first {
                $0.profileId == p.id || (p.steamAppId != nil && $0.appId == p.steamAppId)
            }
            combined.append(
                DisplayGameItem(
                    name: p.name,
                    steamApp: matchedSteam,
                    profile: p,
                    compatibilityStatus: p.compatibilityStatus,
                    isInstalledInSteam: matchedSteam != nil
                )
            )
        }

        // 2. Add ALL remaining installed Steam games (unprofiled / generic)
        for app in steamApps {
            let alreadyAdded = combined.contains { item in
                item.steamApp?.appId == app.appId || (item.profile?.steamAppId != nil && item.profile?.steamAppId == app.appId)
            }
            if !alreadyAdded {
                combined.append(
                    DisplayGameItem(
                        name: app.name,
                        steamApp: app,
                        profile: nil,
                        compatibilityStatus: .requiresWindows,
                        isInstalledInSteam: true
                    )
                )
            }
        }

        self.items = combined
    }

    public var filteredItems: [DisplayGameItem] {
        items.filter { item in
            let matchesSearch = searchQuery.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchQuery) ||
                item.id.localizedCaseInsensitiveContains(searchQuery)

            guard matchesSearch else { return false }

            switch selectedFilter {
            case .all:
                return true
            case .optimized:
                return item.profileState == .optimized
            case .generic:
                return item.profileState == .generic
            case .native:
                return item.compatibilityStatus == .nativeMacOS
            case .compatible:
                return item.compatibilityStatus == .likelyCompatible
            case .offlineOnly:
                return item.profile?.launchPolicy == .allowOfflineOnly || (item.profile?.antiCheat.offlineModeAllowed ?? false)
            case .blocked:
                return item.compatibilityStatus == .notSupported || item.profile?.launchPolicy == .blockKernelAnticheat || (item.profile?.antiCheat.type == .kernelRing0)
            }
        }
    }

    /// Generates a pre-filled GitHub issue URL using profile_request.yml
    public func profileRequestURL(for item: DisplayGameItem) -> URL {
        var components = URLComponents(string: "https://github.com/NicolasBecasAzagra/MacOSGaming/issues/new")!
        let safeName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let kebabId = safeName.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }

        var queryItems = [
            URLQueryItem(name: "template", value: "profile_request.yml"),
            URLQueryItem(name: "title", value: "[PROFILE REQUEST]: \(safeName)"),
            URLQueryItem(name: "game_name", value: safeName),
            URLQueryItem(name: "game_id", value: kebabId)
        ]
        if let appId = item.steamApp?.appId {
            queryItems.append(URLQueryItem(name: "steam_app_id", value: String(appId)))
        }
        components.queryItems = queryItems
        return components.url ?? URL(string: "https://github.com/NicolasBecasAzagra/MacOSGaming/issues/new?template=profile_request.yml")!
    }
}
