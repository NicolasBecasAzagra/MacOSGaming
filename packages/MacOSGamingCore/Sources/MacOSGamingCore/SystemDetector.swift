import Foundation
import Metal

public struct SystemReport: Sendable, Equatable {
    public let chipModel: String
    public let isAppleSilicon: Bool
    public let cpuCores: Int
    public let unifiedMemoryBytes: UInt64
    public let gpuName: String
    public let supportsHardwareRayTracing: Bool
    public let osVersion: String
    public let osMajorVersion: Int
    public let osMarketingName: String
    public let supportsAVX2: Bool
    public var isSequoiaOrLater: Bool { supportsAVX2 }
    public let isRosettaInstalled: Bool
    public let freeDiskSpaceBytes: UInt64
    public let readinessScore: Int

    public var unifiedMemoryGB: Double {
        Double(unifiedMemoryBytes) / (1024 * 1024 * 1024)
    }

    public var freeDiskSpaceGB: Double {
        Double(freeDiskSpaceBytes) / (1024 * 1024 * 1024)
    }

    public init(
        chipModel: String,
        isAppleSilicon: Bool,
        cpuCores: Int,
        unifiedMemoryBytes: UInt64,
        gpuName: String,
        supportsHardwareRayTracing: Bool,
        osVersion: String,
        osMajorVersion: Int,
        osMarketingName: String,
        supportsAVX2: Bool,
        isRosettaInstalled: Bool,
        freeDiskSpaceBytes: UInt64,
        readinessScore: Int
    ) {
        self.chipModel = chipModel
        self.isAppleSilicon = isAppleSilicon
        self.cpuCores = cpuCores
        self.unifiedMemoryBytes = unifiedMemoryBytes
        self.gpuName = gpuName
        self.supportsHardwareRayTracing = supportsHardwareRayTracing
        self.osVersion = osVersion
        self.osMajorVersion = osMajorVersion
        self.osMarketingName = osMarketingName
        self.supportsAVX2 = supportsAVX2
        self.isRosettaInstalled = isRosettaInstalled
        self.freeDiskSpaceBytes = freeDiskSpaceBytes
        self.readinessScore = readinessScore
    }

    public init(
        chipModel: String,
        isAppleSilicon: Bool,
        cpuCores: Int,
        unifiedMemoryBytes: UInt64,
        gpuName: String,
        supportsHardwareRayTracing: Bool,
        osVersion: String,
        isSequoiaOrLater: Bool,
        isRosettaInstalled: Bool,
        freeDiskSpaceBytes: UInt64,
        readinessScore: Int
    ) {
        let parts = osVersion.split(separator: ".").compactMap { Int($0) }
        let major = parts.first ?? (isSequoiaOrLater ? 15 : 14)
        self.init(
            chipModel: chipModel,
            isAppleSilicon: isAppleSilicon,
            cpuCores: cpuCores,
            unifiedMemoryBytes: unifiedMemoryBytes,
            gpuName: gpuName,
            supportsHardwareRayTracing: supportsHardwareRayTracing,
            osVersion: osVersion,
            osMajorVersion: major,
            osMarketingName: SystemDetector.osMarketingName(forMajorVersion: major),
            supportsAVX2: isSequoiaOrLater,
            isRosettaInstalled: isRosettaInstalled,
            freeDiskSpaceBytes: freeDiskSpaceBytes,
            readinessScore: readinessScore
        )
    }
}

public struct SystemDetector: Sendable {
    public init() {}

    public static func osMarketingName(forMajorVersion major: Int) -> String {
        switch major {
        case 11: return "Big Sur"
        case 12: return "Monterey"
        case 13: return "Ventura"
        case 14: return "Sonoma"
        case 15: return "Sequoia"
        case 16...30: return "Tahoe"
        default:
            if major >= 16 {
                return "Tahoe"
            } else if major == 10 {
                return "Catalina"
            } else {
                return "macOS \(major)"
            }
        }
    }

    public static func validateAVX2Support(majorVersion: Int) -> Bool {
        majorVersion >= 15
    }

    public func detect() -> SystemReport {
        let chip = Self.detectChipModel()
        let isAppleSilicon = Self.checkIsAppleSilicon()
        let cores = ProcessInfo.processInfo.processorCount
        let memory = ProcessInfo.processInfo.physicalMemory

        let metalDevice = MTLCreateSystemDefaultDevice()
        let gpuName = metalDevice?.name ?? "Unknown GPU"
        let rayTracing = Self.detectRayTracingSupport(device: metalDevice)

        let osVer = ProcessInfo.processInfo.operatingSystemVersion
        let osString = "\(osVer.majorVersion).\(osVer.minorVersion).\(osVer.patchVersion)"
        let major = osVer.majorVersion
        let supportsAVX2 = Self.validateAVX2Support(majorVersion: major)
        let marketingName = Self.osMarketingName(forMajorVersion: major)

        let rosetta = Self.checkRosettaInstallation()
        let diskSpace = Self.detectFreeDiskSpace()

        let score = Self.calculateReadinessScore(
            isAppleSilicon: isAppleSilicon,
            memoryBytes: memory,
            isSequoia: supportsAVX2,
            rosettaInstalled: rosetta,
            freeDiskBytes: diskSpace
        )

        return SystemReport(
            chipModel: chip,
            isAppleSilicon: isAppleSilicon,
            cpuCores: cores,
            unifiedMemoryBytes: memory,
            gpuName: gpuName,
            supportsHardwareRayTracing: rayTracing,
            osVersion: osString,
            osMajorVersion: major,
            osMarketingName: marketingName,
            supportsAVX2: supportsAVX2,
            isRosettaInstalled: rosetta,
            freeDiskSpaceBytes: diskSpace,
            readinessScore: score
        )
    }

    public static func detectChipModel() -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        guard size > 0 else { return "Apple Silicon" }

        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0)
        let name = buffer.withUnsafeBufferPointer { ptr -> String in
            guard let base = ptr.baseAddress else { return "Apple Silicon" }
            return String(cString: base).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return name.isEmpty ? "Apple Silicon" : name
    }

    public static func checkIsAppleSilicon() -> Bool {
        #if arch(arm64)
        return true
        #else
        return false
        #endif
    }

    public static func detectRayTracingSupport(device: MTLDevice?) -> Bool {
        guard let device = device else { return false }
        if #available(macOS 14.0, *) {
            // Dedicated hardware ray tracing was introduced in Apple family 9 (M3 generation)
            if device.supportsFamily(.apple9) {
                return true
            }
            if let apple10 = MTLGPUFamily(rawValue: 1010), device.supportsFamily(apple10) {
                return true
            }
        }
        return false
    }

    public static func checkRosettaInstallation() -> Bool {
        let runtimePath = "/Library/Apple/usr/libexec/oah/libRosettaRuntime"
        let oahdPath = "/Library/Apple/usr/libexec/oah/oahd"
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: runtimePath) || fileManager.fileExists(atPath: oahdPath)
    }

    public static func detectFreeDiskSpace() -> UInt64 {
        let path = NSHomeDirectory()
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: path),
              let freeSpace = attributes[.systemFreeSize] as? NSNumber else {
            return 0
        }
        return freeSpace.uint64Value
    }

    public static func calculateReadinessScore(
        isAppleSilicon: Bool,
        memoryBytes: UInt64,
        isSequoia: Bool,
        rosettaInstalled: Bool,
        freeDiskBytes: UInt64
    ) -> Int {
        var score = 0

        // 1. Processor Architecture (Apple Silicon M-Series)
        // Apple Silicon is essential for modern high-performance Metal translation & unified memory
        if isAppleSilicon {
            score += 30
        }

        // 2. Memory scoring (Unified Memory Architecture - UMA)
        // In UMA, CPU and GPU share the same physical memory pool.
        // On systems with < 16 GB, the operating system + translation layer + GPU buffers
        // cause severe swapping and memory pressure. Systems under 16 GB are penalised.
        let memoryGB = Double(memoryBytes) / (1024 * 1024 * 1024)
        if memoryGB >= 32 {
            score += 25
        } else if memoryGB >= 16 {
            score += 20
        } else if memoryGB >= 8 {
            // Penalty: 8 GB is severely bottlenecked for shared VRAM + translation
            score -= 10
        } else {
            // Severe penalty: < 8 GB is inadequate for modern gaming runtimes
            score -= 20
        }

        // 3. macOS Version (AVX2 evaluation support in Rosetta 2)
        // macOS 15+ (Sequoia / Tahoe) enables AVX/AVX2 instruction emulation
        if isSequoia {
            score += 20
        } else {
            score += 5
        }

        // 4. Rosetta 2 Translation Environment
        if rosettaInstalled {
            score += 15
        }

        // 5. Storage Space (minimum 25 GB recommended, 50 GB optimal)
        let freeGB = Double(freeDiskBytes) / (1024 * 1024 * 1024)
        if freeGB >= 50 {
            score += 10
        } else if freeGB >= 25 {
            score += 5
        }

        return min(100, max(0, score))
    }
}
