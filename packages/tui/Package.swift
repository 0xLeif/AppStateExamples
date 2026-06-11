// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "tui",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "appstate-tui", targets: ["appstate-tui"]),
        .library(name: "TUICore", targets: ["TUICore"])
    ],
    dependencies: [
        .package(url: "https://github.com/0xLeif/AppState.git", exact: "3.0.0-rc.1")
    ],
    targets: [
        .target(
            name: "TUICore",
            dependencies: [
                .product(name: "AppState", package: "AppState")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "appstate-tui",
            dependencies: [
                "TUICore",
                .product(name: "AppState", package: "AppState")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "TUICoreTests",
            dependencies: [
                "TUICore",
                .product(name: "AppState", package: "AppState")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
