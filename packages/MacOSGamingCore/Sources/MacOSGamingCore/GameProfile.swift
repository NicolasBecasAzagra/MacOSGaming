import Foundation

public enum CompatibilityStatus: String, Codable, Sendable, Equatable {
    case nativeMacOS = "native_macos"
    case likelyCompatible = "likely_compatible"
    case requiresWindows = "requires_windows"
    case notSupported = "not_supported"

    public var displayTitle: String {
        switch self {
        case .nativeMacOS: return "Native macOS"
        case .likelyCompatible: return "Likely Compatible via Compatibility Layer"
        case .requiresWindows: return "Requires Windows"
        case .notSupported: return "Not Legally/Technically Supported"
        }
    }
}

public enum ConfidenceLevel: String, Codable, Sendable, Equatable {
    case verified = "verified"
    case probable = "probable"
    case hypothesis = "hypothesis"
}

public enum AntiCheatType: String, Codable, Sendable, Equatable {
    case kernelRing0 = "kernel_ring0"
    case userspace = "userspace"
    case none = "none"
}

public struct AntiCheatInfo: Codable, Sendable, Equatable {
    public let name: String
    public let type: AntiCheatType
    public let supportedOnMacOS: Bool
    public let offlineModeAllowed: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case supportedOnMacOS = "supported_on_macos"
        case offlineModeAllowed = "offline_mode_allowed"
    }

    public init(name: String, type: AntiCheatType, supportedOnMacOS: Bool, offlineModeAllowed: Bool) {
        self.name = name
        self.type = type
        self.supportedOnMacOS = supportedOnMacOS
        self.offlineModeAllowed = offlineModeAllowed
    }
}

public enum LaunchPolicy: String, Codable, Sendable, Equatable {
    case allowDirect = "allow_direct"
    case allowOfflineOnly = "allow_offline_only"
    case blockKernelAnticheat = "block_kernel_anticheat"
}

public enum GraphicsBackend: String, Codable, Sendable, Equatable {
    case dxmt = "dxmt"
    case d3dmetalUserProvided = "d3dmetal_user_provided"
    case dxvk = "dxvk"
    case metalNative = "metal_native"
}

public struct RecommendedRuntime: Codable, Sendable, Equatable {
    public let graphicsBackend: GraphicsBackend
    public let environmentVariables: [String: String]

    enum CodingKeys: String, CodingKey {
        case graphicsBackend = "graphics_backend"
        case environmentVariables = "environment_variables"
    }

    public init(graphicsBackend: GraphicsBackend, environmentVariables: [String: String]) {
        self.graphicsBackend = graphicsBackend
        self.environmentVariables = environmentVariables
    }
}

public struct GameProfile: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let publisher: String
    public let compatibilityStatus: CompatibilityStatus
    public let confidenceLevel: ConfidenceLevel
    public let lastVerified: String
    public let antiCheat: AntiCheatInfo
    public let launchPolicy: LaunchPolicy
    public let policyNotice: String
    public let recommendedRuntime: RecommendedRuntime
    public let sources: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case publisher
        case compatibilityStatus = "compatibility_status"
        case confidenceLevel = "confidence_level"
        case lastVerified = "last_verified"
        case antiCheat = "anti_cheat"
        case launchPolicy = "launch_policy"
        case policyNotice = "policy_notice"
        case recommendedRuntime = "recommended_runtime"
        case sources
    }

    public init(
        id: String,
        name: String,
        publisher: String,
        compatibilityStatus: CompatibilityStatus,
        confidenceLevel: ConfidenceLevel,
        lastVerified: String,
        antiCheat: AntiCheatInfo,
        launchPolicy: LaunchPolicy,
        policyNotice: String,
        recommendedRuntime: RecommendedRuntime,
        sources: [String]
    ) {
        self.id = id
        self.name = name
        self.publisher = publisher
        self.compatibilityStatus = compatibilityStatus
        self.confidenceLevel = confidenceLevel
        self.lastVerified = lastVerified
        self.antiCheat = antiCheat
        self.launchPolicy = launchPolicy
        self.policyNotice = policyNotice
        self.recommendedRuntime = recommendedRuntime
        self.sources = sources
    }
}
