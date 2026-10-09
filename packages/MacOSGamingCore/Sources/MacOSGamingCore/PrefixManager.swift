import Foundation

public struct PrefixInfo: Sendable, Equatable {
    public let profileId: String
    public let prefixDirectory: URL
    public let driveCDirectory: URL
    public let isInitialized: Bool

    public init(profileId: String, prefixDirectory: URL, driveCDirectory: URL, isInitialized: Bool) {
        self.profileId = profileId
        self.prefixDirectory = prefixDirectory
        self.driveCDirectory = driveCDirectory
        self.isInitialized = isInitialized
    }
}

public struct PrefixManager: Sendable {
    public let basePrefixDirectory: URL

    public init(basePrefixDirectory: URL? = nil) {
        if let base = basePrefixDirectory {
            self.basePrefixDirectory = base
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.basePrefixDirectory = appSupport.appendingPathComponent("MacOSGaming/prefixes")
        }
    }

    public func prefixInfo(for profileId: String) -> PrefixInfo {
        let prefixDir = basePrefixDirectory.appendingPathComponent(profileId)
        let driveC = prefixDir.appendingPathComponent("drive_c")
        let exists = FileManager.default.fileExists(atPath: driveC.path)
        return PrefixInfo(
            profileId: profileId,
            prefixDirectory: prefixDir,
            driveCDirectory: driveC,
            isInitialized: exists
        )
    }

    public func createIsolatedPrefix(for profileId: String) throws -> PrefixInfo {
        let info = prefixInfo(for: profileId)
        let fm = FileManager.default

        // Create prefix root and drive_c mock structure
        try fm.createDirectory(at: info.driveCDirectory, withIntermediateDirectories: true)
        let windowsDir = info.driveCDirectory.appendingPathComponent("windows/system32")
        let programFiles = info.driveCDirectory.appendingPathComponent("Program Files")
        try fm.createDirectory(at: windowsDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: programFiles, withIntermediateDirectories: true)

        // Write sandbox isolation manifest
        let configPath = info.prefixDirectory.appendingPathComponent("sandbox_config.json")
        let configContent = """
        {
          "profile_id": "\(profileId)",
          "isolation_level": "sandboxed_drive_c",
          "disable_root_drive_z": true,
          "created_at": "\(ISO8601DateFormatter().string(from: Date()))"
        }
        """
        try configContent.write(to: configPath, atomically: true, encoding: .utf8)

        return PrefixInfo(
            profileId: profileId,
            prefixDirectory: info.prefixDirectory,
            driveCDirectory: info.driveCDirectory,
            isInitialized: true
        )
    }
}
