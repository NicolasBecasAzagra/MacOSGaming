import Foundation
import Observation
import MacOSGamingCore

public struct DisplayGameItem: Identifiable, Sendable {
    public var id: String { profile?.id ?? "\(steamApp?.appId ?? 0)" }
    public let name: String
    public let steamApp: SteamInstalledApp?
    public let profile: GameProfile?
    public let compatibilityStatus: CompatibilityStatus
    public let isInstalledInSteam: Bool

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

        for app in steamApps {
            if !combined.contains(where: { $0.steamApp?.appId == app.appId }) {
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
}
