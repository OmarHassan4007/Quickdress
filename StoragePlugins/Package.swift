// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StoragePlugins",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "StoragePlugins", targets: ["StoragePlugins"]),
    ],
    dependencies: [
        .package(path: "../QuickdressCore"),
    ],
    targets: [
        .target(
            name: "StoragePlugins",
            dependencies: [.product(name: "QuickdressCore", package: "QuickdressCore")]
        ),
        .testTarget(
            name: "StoragePluginsTests",
            dependencies: ["StoragePlugins", .product(name: "QuickdressCore", package: "QuickdressCore")]
        ),
    ]
)
