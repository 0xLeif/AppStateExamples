import SwiftUI
import AppState

// MARK: - App Entry Point

/// Root of the MenuBarDemo app.
///
/// Demonstrates AppState 3.0 powering a native macOS menu-bar accessory (`MenuBarExtra`).
/// The menu-bar title reflects the live `clickCount` state so the badge updates as you click.
@main
internal struct MenuBarDemoApp: App {

    // MARK: State

    /// Read click count at the app level so the menu-bar title label stays current.
    @AppState(\.clickCount) private var clickCount: Int

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
