// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Sanctuary",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Sanctuary",
            targets: ["Sanctuary"]
        ),
    ],
    dependencies: [
        // No external dependencies - using native frameworks only
    ],
    targets: [
        .target(
            name: "Sanctuary",
            dependencies: [],
            path: "Sanctuary"
        ),
        .testTarget(
            name: "SanctuaryTests",
            dependencies: ["Sanctuary"],
            path: "SanctuaryTests"
        ),
    ]
)
