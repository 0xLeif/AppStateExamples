// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "observability",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AppStateObservability",
            targets: ["AppStateObservability"]
        ),
        .executable(
            name: "observability-demo",
            targets: ["observability-demo"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/0xLeif/AppState.git", exact: "3.0.0")
    ],
    targets: [
        .target(
            name: "AppStateObservability",
            dependencies: [
                .product(name: "AppState", package: "AppState")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "observability-demo",
            dependencies: [
                "AppStateObservability",
                .product(name: "AppState", package: "AppState")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AppStateObservabilityTests",
            dependencies: [
                "AppStateObservability",
                .product(name: "AppState", package: "AppState")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
