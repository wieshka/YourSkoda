// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "YourSkoda",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "YourSkoda",
            path: "Sources/YourSkoda"
        )
    ]
)
