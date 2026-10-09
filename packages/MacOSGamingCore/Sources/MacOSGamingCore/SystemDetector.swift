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
    public let isSequoiaOrLater: Bool
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
        isSequoiaOrLater: Bool,
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
        self.isSequoiaOrLater = isSequoiaOrLater
        self.isRosettaInstalled = isRosettaInstalled
        self.freeDiskSpaceBytes = freeDiskSpaceBytes
        self.readinessScore = readinessScore
    }
}

public struct SystemDetector: Sendable {
    public init() {}

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
        let isSequoia = osVer.majorVersion >= 15

        let rosetta = Self.checkRosettaInstallation()
        let diskSpace = Self.detectFreeDiskSpace()

        let score = Self.calculateReadinessScore(
            isAppleSilicon: isAppleSilicon,
            memoryBytes: memory,
            isSequoia: isSequoia,
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
            isSequoiaOrLater: isSequoia,
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

        // Apple Silicon is essential for modern high-performance Metal translation
        if isAppleSilicon { score += 30 }

        // Memory scoring (UMA)
        let memoryGB = Double(memoryBytes) / (1024 * 1024 * 1024)
        if memoryGB >= 16 {
            score += 25
        } else if memoryGB >= 8 {
            score += 15
        }

        // macOS version (Sequoia 15+ has AVX2 evaluation support in Rosetta 2)
        if isSequoia {
            score += 20
        } else {
            score += 10
        }

        // Rosetta 2 presence
        if rosettaInstalled {
            score += 15
        }

        // Storage space (minimum 25 GB recommended)
        let freeGB = Double(freeDiskBytes) / (1024 * 1024 * 1024)
        if freeGB >= 50 {
            score += 10
        } else if freeGB >= 25 {
            score += 5
        }

        return min(100, max(0, score))
    }
}
