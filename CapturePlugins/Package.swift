// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapturePlugins",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CapturePlugins", targets: ["CapturePlugins"]),
    ],
    dependencies: [
        .package(path: "../QuickdressCore"),
    ],
    targets: [
        .target(
            name: "CapturePlugins",
            dependencies: [.product(name: "QuickdressCore", package: "QuickdressCore")]
        ),
        .testTarget(
            name: "CapturePluginsTests",
            dependencies: ["CapturePlugins", .product(name: "QuickdressCore", package: "QuickdressCore")],
            resources: [.copy("Fixtures")]
        ),
    ]
)
