import Foundation

public enum DependencyCategory: String, Codable, Sendable, CaseIterable {
    case runner = "Runner"
    case graphicsTranslator = "Graphics Translator"
    case runtimePrerequisite = "Runtime Prerequisite"
}

public struct GameDependency: Identifiable, Sendable, Equatable {
    public var id: String { dependencyId }
    public let dependencyId: String
    public let name: String
    public let category: DependencyCategory
    public let sizeInMB: Double
    public let officialSourceURL: URL
    public let downloadURL: URL?
    public let targetFilename: String
    public let isRequired: Bool
    public let licenseType: String

    public var formattedSize: String {
        String(format: "%.1f MB", sizeInMB)
    }

    public init(
        dependencyId: String,
        name: String,
        category: DependencyCategory,
        sizeInMB: Double,
        officialSourceURL: URL,
        downloadURL: URL? = nil,
        targetFilename: String,
        isRequired: Bool = true,
        licenseType: String
    ) {
        self.dependencyId = dependencyId
        self.name = name
        self.category = category
        self.sizeInMB = sizeInMB
        self.officialSourceURL = officialSourceURL
        self.downloadURL = downloadURL
        self.targetFilename = targetFilename
        self.isRequired = isRequired
        self.licenseType = licenseType
    }
}

public struct PrefixDependencyManifest: Codable, Sendable, Equatable {
    public struct InstalledRecord: Codable, Sendable, Equatable {
        public let dependencyId: String
        public let name: String
        public let sizeInMB: Double
        public let officialSourceURL: String
        public let installedAt: Date
        public let filename: String

        public init(
            dependencyId: String,
            name: String,
            sizeInMB: Double,
            officialSourceURL: String,
            installedAt: Date = Date(),
            filename: String
        ) {
            self.dependencyId = dependencyId
            self.name = name
            self.sizeInMB = sizeInMB
            self.officialSourceURL = officialSourceURL
            self.installedAt = installedAt
            self.filename = filename
        }
    }

    public var profileId: String
    public var records: [InstalledRecord]

    public init(profileId: String, records: [InstalledRecord] = []) {
        self.profileId = profileId
        self.records = records
    }

    public func isInstalled(dependencyId: String) -> Bool {
        records.contains { $0.dependencyId == dependencyId }
    }

    public mutating func recordInstallation(of dependency: GameDependency) {
        if let idx = records.firstIndex(where: { $0.dependencyId == dependency.dependencyId }) {
            records[idx] = InstalledRecord(
                dependencyId: dependency.dependencyId,
                name: dependency.name,
                sizeInMB: dependency.sizeInMB,
                officialSourceURL: dependency.officialSourceURL.absoluteString,
                installedAt: Date(),
                filename: dependency.targetFilename
            )
        } else {
            records.append(
                InstalledRecord(
                    dependencyId: dependency.dependencyId,
                    name: dependency.name,
                    sizeInMB: dependency.sizeInMB,
                    officialSourceURL: dependency.officialSourceURL.absoluteString,
                    installedAt: Date(),
                    filename: dependency.targetFilename
                )
            )
        }
    }
}
