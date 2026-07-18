import SwiftUI
import AppState

// MARK: - App Entry Point

/// Root of the MenuBarDemo app.
///
/// Demonstrates AppState 3.0 powering a native macOS menu-bar accessory (`MenuBarExtra`).
/// The menu-bar title reflects the live `clickCount` state so the badge updates as you click.
@main
internal struct MenuBarDemoApp: App {

    // MARK: Properties

    /// Retains the local iCloud-KV fallback override for the lifetime of the process.
    /// Without it, local builds lacking the ubiquity KV entitlement crash the moment
    /// `SyncState` touches `NSUbiquitousKeyValueStore`.
    private static let syncFallbackToken: Application.DependencyOverride? = {
        Application.useLocalSyncStoreIfNeeded()
    }()

    // MARK: State

    /// Read click count at the app level so the menu-bar title label stays current.
    @AppState(\.clickCount) private var clickCount: Int

    // MARK: Initializer

    /// Installs the sync fallback override before any `SyncState` resolves.
    @MainActor
    internal init() {
        // Accessing the static property triggers the lazy initializer on the main actor.
        _ = MenuBarDemoApp.syncFallbackToken
    }

    // MARK: Body

    internal var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView()
        } label: {
            Label(
                clickCount == 0 ? "AppState" : "\(clickCount)",
                systemImage: "sparkles"
            )
        }
        .menuBarExtraStyle(.window)
    }
}
