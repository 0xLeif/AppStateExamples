// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "appstate-vapor-example",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "vapor-example", targets: ["vapor-example"]),
        .library(name: "AppStateVaporCore", targets: ["AppStateVaporCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/0xLeif/AppState.git", exact: "3.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", exact: "4.121.4")
    ],
    targets: [
        .target(
            name: "AppStateVaporCore",
            dependencies: [
                .product(name: "AppState", package: "AppState"),
                .product(name: "Vapor", package: "vapor")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "vapor-example",
            dependencies: [
                "AppStateVaporCore"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AppStateVaporCoreTests",
            dependencies: [
                "AppStateVaporCore",
                .product(name: "AppState", package: "AppState"),
                .product(name: "XCTVapor", package: "vapor")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
