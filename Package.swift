// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MacOSGaming",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MacOSGamingCore",
            targets: ["MacOSGamingCore"]
        ),
        .executable(
            name: "macosgaming",
            targets: ["MacOSGamingCLI"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MacOSGamingCore",
            dependencies: [],
            path: "packages/MacOSGamingCore/Sources/MacOSGamingCore"
        ),
        .executableTarget(
            name: "MacOSGamingCLI",
            dependencies: ["MacOSGamingCore"],
            path: "packages/MacOSGamingCLI/Sources/MacOSGamingCLI"
        ),
        .testTarget(
            name: "MacOSGamingCoreTests",
            dependencies: ["MacOSGamingCore"],
            path: "packages/MacOSGamingCore/Tests/MacOSGamingCoreTests"
        )
    ]
)
