import Foundation
import SwiftUI
import AppState

// MARK: - App Entry Point

/// Root of the SwiftUI Demo app, which catalogs every AppState 3.0 feature.
@main
internal struct SwiftUIDemoApp: App {

    // MARK: Initializer

    internal init() {
        DemoLaunchConfiguration.applyIfNeeded(arguments: ProcessInfo.processInfo.arguments)
    }

    // MARK: Body

    internal var body: some Scene {
        WindowGroup {
            RootCatalogView()
        }
        #if canImport(SwiftData)
        .modelContainer(Application.dependency(\.container))
        #endif
    }
}
