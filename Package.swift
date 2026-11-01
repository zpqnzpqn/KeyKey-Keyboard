// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyKey",
    defaultLocalization: "zh-Hant",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "KeyKey",
            targets: ["KeyKey"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "KeyKey",
            path: "KeyKey",
            exclude: [
                "Resources/Info.plist"
            ],
            resources: [
                .process("Resources/Assets.xcassets"),
                .process("Resources/Localizable.xcstrings")
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("AppKit")
            ]
        )
    ]
)
