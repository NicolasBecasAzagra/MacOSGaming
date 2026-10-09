import Foundation

public struct DependencyInfo: Sendable, Equatable {
    public let name: String
    public let isInstalled: Bool
    public let installedPath: String?
    public let version: String?
    public let officialSourceURL: String
    public let installationInstructions: String
    public let licenseType: String

    public init(
        name: String,
        isInstalled: Bool,
        installedPath: String?,
        version: String?,
        officialSourceURL: String,
        installationInstructions: String,
        licenseType: String
    ) {
        self.name = name
        self.isInstalled = isInstalled
        self.installedPath = installedPath
        self.version = version
        self.officialSourceURL = officialSourceURL
        self.installationInstructions = installationInstructions
        self.licenseType = licenseType
    }
}

public struct DependencyManager: Sendable {
    private let fileManager: FileManager
    private let customRuntimesDirectory: URL?

    public init(customRuntimesDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.customRuntimesDirectory = customRuntimesDirectory
        self.fileManager = fileManager
    }

    /// Root directory for external runtimes managed by MacOSGaming
    public var runtimesDirectory: URL {
        if let custom = customRuntimesDirectory {
            return custom
        }
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        return home.appendingPathComponent("Library/Application Support/MacOSGaming/runtimes", isDirectory: true)
    }

    /// Ensures runtime directories exist
    public func ensureRuntimeDirectories() throws {
        let root = runtimesDirectory
        let subdirs = ["wine", "dxmt", "dxvk", "downloads"]
        for sub in subdirs {
            let dir = root.appendingPathComponent(sub, isDirectory: true)
            if !fileManager.fileExists(atPath: dir.path) {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }
        }
    }

    /// Checks the installation status of all required and recommended gaming dependencies
    public func checkDependencies() -> [DependencyInfo] {
        var dependencies: [DependencyInfo] = []

        // 1. Rosetta 2
        let rosettaInstalled = SystemDetector.checkRosettaInstallation()
        dependencies.append(DependencyInfo(
            name: "Rosetta 2 Translation Runtime",
            isInstalled: rosettaInstalled,
            installedPath: rosettaInstalled ? "/Library/Apple/usr/libexec/oah/libRosettaRuntime" : nil,
            version: "macOS System Built-in",
            officialSourceURL: "https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment",
            installationInstructions: "softwareupdate --install-rosetta --agree-to-license",
            licenseType: "Apple macOS System Component"
        ))

        // 2. Wine-CX (Wine Darwin with Mach Synchronization)
        let winePath = resolveWineBinary()
        dependencies.append(DependencyInfo(
            name: "Wine-CX Runtime (wine64)",
            isInstalled: winePath != nil,
            installedPath: winePath,
            version: winePath != nil ? "Detected" : nil,
            officialSourceURL: "https://github.com/Gcenx/winecx/releases",
            installationInstructions: "brew install --cask gcenx/wine/wine-crossover\n   OR download release tarball from https://github.com/Gcenx/winecx/releases into ~/Library/Application Support/MacOSGaming/runtimes/wine",
            licenseType: "LGPL v2.1+"
        ))

        // 3. DXMT (Direct3D 11 to Metal Translation Layer)
        let dxmtPath = resolveDXMTDirectory()
        dependencies.append(DependencyInfo(
            name: "DXMT (Direct3D 11 -> Metal)",
            isInstalled: dxmtPath != nil,
            installedPath: dxmtPath?.path,
            version: dxmtPath != nil ? "Installed" : nil,
            officialSourceURL: "https://github.com/3Shain/dxmt/releases",
            installationInstructions: "Download latest dxmt.tar.gz from https://github.com/3Shain/dxmt/releases and extract d3d11.dll / dxgi.dll into ~/Library/Application Support/MacOSGaming/runtimes/dxmt/",
            licenseType: "LGPL v2.1+ / MIT"
        ))

        // 4. DXVK-macOS (Direct3D 9/10/11 -> Vulkan / MoltenVK)
        let dxvkPath = resolveDXVKDirectory()
        dependencies.append(DependencyInfo(
            name: "DXVK-macOS (Direct3D 9-11 -> MoltenVK)",
            isInstalled: dxvkPath != nil,
            installedPath: dxvkPath?.path,
            version: dxvkPath != nil ? "Installed" : nil,
            officialSourceURL: "https://github.com/Gcenx/DXVK-macOS/releases",
            installationInstructions: "Download latest dxvk release from https://github.com/Gcenx/DXVK-macOS/releases into ~/Library/Application Support/MacOSGaming/runtimes/dxvk/",
            licenseType: "Zlib / MIT"
        ))

        // 5. Apple D3DMetal (Optional Developer Evaluation Only)
        let d3dmetalDetected = checkD3DMetalEvaluationMounted()
        dependencies.append(DependencyInfo(
            name: "Apple D3DMetal (Optional Developer Evaluation)",
            isInstalled: d3dmetalDetected,
            installedPath: d3dmetalDetected ? "/Volumes/Game Porting Toolkit" : nil,
            version: "Evaluation DMG",
            officialSourceURL: "https://developer.apple.com/games/",
            installationInstructions: "Log in with Apple ID at developer.apple.com/download/all/ and mount 'Game Porting Toolkit' evaluation DMG. MacOSGaming detects local mount point automatically without downloading proprietary code.",
            licenseType: "Apple Evaluation License (Strict Developer Testing Only)"
        ))

        return dependencies
    }

    /// Locates an active wine64 binary on the machine
    public func resolveWineBinary() -> String? {
        // 1. Local application support runtime
        let localWine = runtimesDirectory.appendingPathComponent("wine/bin/wine64").path
        if fileManager.isExecutableFile(atPath: localWine) {
            return localWine
        }

        // 2. Homebrew standard installation paths
        let homebrewARM = "/opt/homebrew/bin/wine64"
        if fileManager.isExecutableFile(atPath: homebrewARM) {
            return homebrewARM
        }
        let homebrewIntel = "/usr/local/bin/wine64"
        if fileManager.isExecutableFile(atPath: homebrewIntel) {
            return homebrewIntel
        }

        // 3. System PATH check via /usr/bin/which
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["wine64"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty && fileManager.isExecutableFile(atPath: output) {
                return output
            }
        }

        return nil
    }

    /// Checks if DXMT translation DLLs are installed in the runtimes directory
    public func resolveDXMTDirectory() -> URL? {
        let dxmtDir = runtimesDirectory.appendingPathComponent("dxmt", isDirectory: true)
        let d3d11 = dxmtDir.appendingPathComponent("d3d11.dll")
        let x64d3d11 = dxmtDir.appendingPathComponent("x64/d3d11.dll")
        if fileManager.fileExists(atPath: d3d11.path) || fileManager.fileExists(atPath: x64d3d11.path) {
            return dxmtDir
        }
        return nil
    }

    /// Checks if DXVK translation DLLs are installed in the runtimes directory
    public func resolveDXVKDirectory() -> URL? {
        let dxvkDir = runtimesDirectory.appendingPathComponent("dxvk", isDirectory: true)
        let dxgi = dxvkDir.appendingPathComponent("dxgi.dll")
        let x64dxgi = dxvkDir.appendingPathComponent("x64/dxgi.dll")
        if fileManager.fileExists(atPath: dxgi.path) || fileManager.fileExists(atPath: x64dxgi.path) {
            return dxvkDir
        }
        return nil
    }

    /// Verifies if an Apple Game Porting Toolkit evaluation DMG is locally mounted
    public func checkD3DMetalEvaluationMounted() -> Bool {
        let candidatePaths = [
            "/Volumes/Game Porting Toolkit",
            "/Volumes/Game Porting Toolkit 2"
        ]
        for path in candidatePaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }

    // MARK: - Per-Game Dependency Resolution

    /// Returns the full list of dependencies required by a specific game profile
    public func resolveGameDependencies(for profile: GameProfile) -> [GameDependency] {
        var deps: [GameDependency] = []

        // If game is native macOS, no Wine/DX translation layers needed
        if profile.compatibilityStatus == .nativeMacOS {
            return deps
        }

        // 1. Wine-CX Runtime is required for all Windows binaries
        deps.append(
            GameDependency(
                dependencyId: "wine-cx",
                name: "Wine-CX Runtime (wine64)",
                category: .runner,
                sizeInMB: 120.0,
                officialSourceURL: URL(string: "https://github.com/Gcenx/winecx/releases")!,
                downloadURL: URL(string: "https://github.com/Gcenx/winecx/releases/latest/download/wine-crossover.tar.xz"),
                targetFilename: "wine64",
                isRequired: true,
                licenseType: "LGPL v2.1+"
            )
        )

        // 2. Graphics Translation Layer based on profile
        switch profile.recommendedRuntime.graphicsBackend {
        case .dxmt:
            deps.append(
                GameDependency(
                    dependencyId: "dxmt",
                    name: "DXMT Translation Layer (Direct3D 11 -> Metal)",
                    category: .graphicsTranslator,
                    sizeInMB: 15.5,
                    officialSourceURL: URL(string: "https://github.com/3Shain/dxmt/releases")!,
                    downloadURL: URL(string: "https://github.com/3Shain/dxmt/releases/latest/download/dxmt.tar.gz"),
                    targetFilename: "d3d11.dll",
                    isRequired: true,
                    licenseType: "LGPL v2.1+ / MIT"
                )
            )
        case .dxvk:
            deps.append(
                GameDependency(
                    dependencyId: "dxvk",
                    name: "DXVK-macOS (Direct3D 9-11 -> MoltenVK)",
                    category: .graphicsTranslator,
                    sizeInMB: 18.2,
                    officialSourceURL: URL(string: "https://github.com/Gcenx/DXVK-macOS/releases")!,
                    downloadURL: URL(string: "https://github.com/Gcenx/DXVK-macOS/releases/latest/download/dxvk-macOS.tar.gz"),
                    targetFilename: "dxgi.dll",
                    isRequired: true,
                    licenseType: "Zlib / MIT"
                )
            )
        case .d3dmetalUserProvided:
            deps.append(
                GameDependency(
                    dependencyId: "d3dmetal",
                    name: "Apple D3DMetal (Developer Evaluation DMG)",
                    category: .graphicsTranslator,
                    sizeInMB: 0.0,
                    officialSourceURL: URL(string: "https://developer.apple.com/games/")!,
                    downloadURL: nil,
                    targetFilename: "libd3dshared.dylib",
                    isRequired: true,
                    licenseType: "Apple Evaluation License"
                )
            )
        case .metalNative:
            break
        }

        // 3. Visual C++ Redistributable (VC++ 2015-2022) runtime libraries
        if profile.compatibilityStatus == .likelyCompatible || profile.compatibilityStatus == .requiresWindows {
            deps.append(
                GameDependency(
                    dependencyId: "vcredist",
                    name: "Microsoft Visual C++ 2015-2022 Redistributable (x64)",
                    category: .runtimePrerequisite,
                    sizeInMB: 24.1,
                    officialSourceURL: URL(string: "https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist")!,
                    downloadURL: URL(string: "https://aka.ms/vs/17/release/vc_redist.x64.exe"),
                    targetFilename: "vc_redist.x64.exe",
                    isRequired: false,
                    licenseType: "Microsoft Software License"
                )
            )
        }

        return deps
    }

    /// Checks which dependencies are currently missing for a specific game profile and its prefix
    public func checkMissingDependencies(for profile: GameProfile, prefixManager: PrefixManager = PrefixManager()) -> [GameDependency] {
        let allRequired = resolveGameDependencies(for: profile)
        let manifest = prefixManager.loadManifest(for: profile.id)

        var missing: [GameDependency] = []

        for dep in allRequired {
            // 1. If already recorded as installed in the prefix manifest, skip
            if manifest.isInstalled(dependencyId: dep.dependencyId) {
                continue
            }

            // 2. Check if already present on host system
            switch dep.dependencyId {
            case "wine-cx":
                if resolveWineBinary() != nil {
                    continue
                }
            case "dxmt":
                if resolveDXMTDirectory() != nil {
                    continue
                }
            case "dxvk":
                if resolveDXVKDirectory() != nil {
                    continue
                }
            case "d3dmetal":
                if checkD3DMetalEvaluationMounted() {
                    continue
                }
            default:
                break
            }

            missing.append(dep)
        }

        return missing
    }
}
