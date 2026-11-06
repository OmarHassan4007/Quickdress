// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuickdressCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "QuickdressCore", targets: ["QuickdressCore"]),
    ],
    targets: [
        .target(name: "QuickdressCore"),
        .testTarget(name: "QuickdressCoreTests", dependencies: ["QuickdressCore"]),
    ]
)
