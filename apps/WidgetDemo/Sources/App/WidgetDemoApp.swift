import SwiftUI
import AppState
import WidgetDemoCore

// MARK: - App Entry Point

/// Root of the WidgetDemo app.
///
/// On launch, `Application.useSharedDefaults()` redirects AppState's `userDefaults`
/// dependency to the App Group suite so that `StoredState` values are visible to
/// the widget extension running in a separate process.
@main
internal struct WidgetDemoApp: App {

    // MARK: Properties

    /// Retains the override token for the lifetime of the app process.
    /// Stored as a static to avoid any SwiftUI lifecycle teardown issues.
    private static let sharedDefaultsToken: Application.DependencyOverride? = {
        Application.useSharedDefaults()
    }()

    // MARK: Initializer

    /// Ensures the shared-defaults override is installed before any scene renders.
    @MainActor
    internal init() {
        // Accessing the static property triggers the lazy initializer on the main actor.
        _ = WidgetDemoApp.sharedDefaultsToken
        if ProcessInfo.processInfo.arguments.contains("-ResetDemoState") {
            var title = Application.storedState(\.focusTitle)
            title.value = "Focus Session"
            var count = Application.storedState(\.focusCount)
            count.value = 0
        }
    }

    // MARK: Body

    internal var body: some Scene {
        WindowGroup {
            FocusEditorView()
        }
    }
}
