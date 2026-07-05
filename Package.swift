// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "DofusTabs",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DofusTabs",
            path: "Sources/DofusTabs",
            resources: [.process("Resources")]
        )
    ]
)
