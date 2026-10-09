import Foundation

public struct SteamInstalledApp: Sendable, Equatable, Identifiable {
    public var id: Int { appId }
    public let appId: Int
    public let name: String
    public let installDir: String
    public let installPath: URL
    public let executablePath: URL?
    public let profileId: String?
    public let isFullyInstalled: Bool

    public init(
        appId: Int,
        name: String,
        installDir: String,
        installPath: URL,
        executablePath: URL? = nil,
        profileId: String? = nil,
        isFullyInstalled: Bool = true
    ) {
        self.appId = appId
        self.name = name
        self.installDir = installDir
        self.installPath = installPath
        self.executablePath = executablePath
        self.profileId = profileId
        self.isFullyInstalled = isFullyInstalled
    }
}

public struct SteamLibraryDetector: Sendable {
    private let fileManager: FileManager
    private let customSteamDirectory: URL?

    public init(customSteamDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.customSteamDirectory = customSteamDirectory
        self.fileManager = fileManager
    }

    /// Resolves the primary Steam directory on macOS
    public var steamRootDirectory: URL {
        if let custom = customSteamDirectory {
            return custom
        }
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        return home.appendingPathComponent("Library/Application Support/Steam", isDirectory: true)
    }

    /// Discovers all Steam library folders (primary + secondary storage drives)
    public func discoverLibraryFolders() -> [URL] {
        var folders: [URL] = []
        let root = steamRootDirectory

        // 1. Primary library folder
        if fileManager.fileExists(atPath: root.path) {
            folders.append(root)
        }

        // 2. Secondary library folders configured in steamapps/libraryfolders.vdf
        let vdfPath = root.appendingPathComponent("steamapps/libraryfolders.vdf")
        if fileManager.fileExists(atPath: vdfPath.path),
           let content = try? String(contentsOf: vdfPath, encoding: .utf8) {
            let extracted = parseLibraryFoldersVDF(content: content)
            for path in extracted {
                let url = URL(fileURLWithPath: path, isDirectory: true)
                if fileManager.fileExists(atPath: url.path) && !folders.contains(url) {
                    folders.append(url)
                }
            }
        }

        return folders
    }

    /// Scans all library folders and discovers installed Steam games
    public func detectInstalledApps(profileRepository: GameProfileRepository = GameProfileRepository()) -> [SteamInstalledApp] {
        let libraries = discoverLibraryFolders()
        var discovered: [SteamInstalledApp] = []

        for library in libraries {
            let steamappsDir = library.appendingPathComponent("steamapps", isDirectory: true)
            guard let contents = try? fileManager.contentsOfDirectory(atPath: steamappsDir.path) else {
                continue
            }

            for item in contents where item.hasPrefix("appmanifest_") && item.hasSuffix(".acf") {
                let manifestURL = steamappsDir.appendingPathComponent(item)
                guard let content = try? String(contentsOf: manifestURL, encoding: .utf8),
                      let app = parseAppManifest(content: content, libraryRoot: library, profileRepository: profileRepository) else {
                    continue
                }
                discovered.append(app)
            }
        }

        return discovered.sorted { $0.name < $1.name }
    }

    /// Finds a specific installed Steam app by AppID
    public func findApp(appId: Int, profileRepository: GameProfileRepository = GameProfileRepository()) -> SteamInstalledApp? {
        detectInstalledApps(profileRepository: profileRepository).first { $0.appId == appId }
    }

    /// Finds a specific installed Steam app matching a MacOSGaming profile ID
    public func findApp(forProfileId profileId: String, profileRepository: GameProfileRepository = GameProfileRepository()) -> SteamInstalledApp? {
        guard let profile = profileRepository.profile(for: profileId) else {
            return nil
        }
        let apps = detectInstalledApps(profileRepository: profileRepository)

        // Try direct Steam App ID match
        if let targetAppId = profile.steamAppId,
           let app = apps.first(where: { $0.appId == targetAppId }) {
            return app
        }

        // Fallback: match by profile ID tag or case-insensitive name match
        return apps.first { app in
            app.profileId == profile.id || app.name.localizedCaseInsensitiveContains(profile.name)
        }
    }

    // MARK: - Internal Parsers & Helpers

    /// Parses libraryfolders.vdf and returns directory paths
    public func parseLibraryFoldersVDF(content: String) -> [String] {
        var paths: [String] = []
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.lowercased().hasPrefix("\"path\"") {
                // Extract value between second pair of quotes
                let parts = trimmed.split(separator: "\"").map(String.init)
                if parts.count >= 3 {
                    let path = parts[parts.count - 1]
                    if !path.isEmpty {
                        paths.append(path)
                    }
                }
            }
        }
        return paths
    }

    /// Parses an appmanifest_<appid>.acf file and builds SteamInstalledApp
    public func parseAppManifest(
        content: String,
        libraryRoot: URL,
        profileRepository: GameProfileRepository
    ) -> SteamInstalledApp? {
        var appId: Int?
        var name: String?
        var installDir: String?
        var stateFlags: Int?

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let quoteParts = trimmed.split(separator: "\"").map(String.init).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            if quoteParts.count >= 2 {
                let key = quoteParts[0].lowercased()
                let value = quoteParts[1]

                switch key {
                case "appid":
                    appId = Int(value)
                case "name":
                    name = value
                case "installdir":
                    installDir = value
                case "stateflags":
                    stateFlags = Int(value)
                default:
                    break
                }
            }
        }

        guard let validAppId = appId,
              let validName = name,
              let validInstallDir = installDir else {
            return nil
        }

        let commonDir = libraryRoot.appendingPathComponent("steamapps/common", isDirectory: true)
        let installPath = commonDir.appendingPathComponent(validInstallDir, isDirectory: true)

        let executable = locateExecutable(in: installPath)
        let matchedProfile = profileRepository.profile(forSteamAppId: validAppId)

        let isFullyInstalled = (stateFlags ?? 4) == 4

        return SteamInstalledApp(
            appId: validAppId,
            name: validName,
            installDir: validInstallDir,
            installPath: installPath,
            executablePath: executable,
            profileId: matchedProfile?.id,
            isFullyInstalled: isFullyInstalled
        )
    }

    /// Scans a game's install directory for the primary executable (.exe or .app)
    public func locateExecutable(in installPath: URL) -> URL? {
        guard fileManager.fileExists(atPath: installPath.path) else { return nil }

        guard let enumerator = fileManager.enumerator(
            at: installPath,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        var candidates: [URL] = []
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            let filename = fileURL.lastPathComponent.lowercased()

            // Skip uninstallation, crash report, and DirectX setup utilities
            if filename.contains("unins") || filename.contains("crash") || filename.contains("dxsetup") || filename.contains("redist") {
                continue
            }

            if ext == "exe" || ext == "app" {
                candidates.append(fileURL)
            }
        }

        // Prefer .exe directly in root or binary subdirectories
        return candidates.first
    }
}
