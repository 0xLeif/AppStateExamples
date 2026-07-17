// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "testing-showcase",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "TestingShowcase", targets: ["TestingShowcase"])
    ],
    dependencies: [
        .package(url: "https://github.com/0xLeif/AppState.git", exact: "3.0.0")
    ],
    targets: [
        .target(
            name: "TestingShowcase",
            dependencies: [
                .product(name: "AppState", package: "AppState")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "TestingShowcaseTests",
            dependencies: [
                "TestingShowcase",
                .product(name: "AppState", package: "AppState")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
