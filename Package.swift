// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sanctuary",
    platforms: [
        .iOS(.v17) // SPM uses .v17, actual deployment target set in project.yml
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
