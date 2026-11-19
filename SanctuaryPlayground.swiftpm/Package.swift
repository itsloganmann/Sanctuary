// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Sanctuary",
    platforms: [
        .iOS("18.0")
    ],
    products: [
        .iOSApplication(
            name: "Sanctuary",
            targets: ["Sanctuary"],
            bundleIdentifier: "com.loganmann.sanctuary-playground",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .heart),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [.portrait],
            appCategory: .healthcareFitness
        )
    ],
    targets: [
        .executableTarget(
            name: "Sanctuary",
            path: "Sources"
        )
    ]
)
