// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "cli",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "appstate-cli", targets: ["appstate-cli"]),
        .library(name: "AppStateCLICore", targets: ["AppStateCLICore"])
    ],
    dependencies: [
        .package(url: "https://github.com/0xLeif/AppState.git", exact: "3.0.1")
    ],
    targets: [
        .target(
            name: "AppStateCLICore",
            dependencies: [
                .product(name: "AppState", package: "AppState")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "appstate-cli",
            dependencies: [
                "AppStateCLICore"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AppStateCLICoreTests",
            dependencies: [
                "AppStateCLICore",
                .product(name: "AppState", package: "AppState")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
