// swift-tools-version: 6.0
import PackageDescription

// The `platforms` floor only constrains Apple HOST tooling (so `swift test` can build the
// host-runnable `WASMCore` target against AppState's macOS 14 minimum). It is ignored when
// building for WebAssembly via the Swift SDK:
//   swift build --swift-sdk wasm32-unknown-wasi
// or use `carton dev` (see README.md). The browser executable still requires the wasm SDK
// because JavaScriptKit has no host implementation.

let package = Package(
    name: "wasm-example",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "wasm-example", targets: ["wasm-example"]),
        .library(name: "WASMCore", targets: ["WASMCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/0xLeif/AppState.git", exact: "3.0.0-rc.1"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.19.0")
    ],
    targets: [
        // MARK: - Pure logic library (host-runnable, no JavaScriptKit)
        .target(
            name: "WASMCore",
            dependencies: [
                .product(name: "AppState", package: "AppState")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // MARK: - Browser executable (requires wasm32-unknown-wasi SDK)
        .executableTarget(
            name: "wasm-example",
            dependencies: [
                "WASMCore",
                .product(name: "AppState", package: "AppState"),
                // Only linked for the WebAssembly SDK; on an Apple host the browser code is
                // excluded via `#if canImport(JavaScriptKit)`, leaving an empty executable so
                // `WASMCore` and its tests still build and run.
                .product(name: "JavaScriptKit", package: "JavaScriptKit", condition: .when(platforms: [.wasi]))
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // MARK: - Host-runnable unit tests (Foundation only, no JavaScriptKit)
        .testTarget(
            name: "WASMCoreTests",
            dependencies: [
                "WASMCore",
                .product(name: "AppState", package: "AppState")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
