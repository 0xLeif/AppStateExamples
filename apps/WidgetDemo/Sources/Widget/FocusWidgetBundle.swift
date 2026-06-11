import WidgetKit
import SwiftUI
import AppState

// MARK: - Widget Bundle Entry Point

/// Entry point for the Focus Widget extension.
///
/// Installs the shared App Group `UserDefaults` override before any widget
/// timeline is requested, ensuring `StoredState` values resolve from the
/// same container used by the host app.
@main
internal struct FocusWidgetBundle: WidgetBundle {

    // MARK: Properties

    /// Retains the override token for the lifetime of the extension process.
    private static let sharedDefaultsToken: Application.DependencyOverride? = {
        Application.useSharedDefaults()
    }()

    // MARK: Initializer

    @MainActor
    internal init() {
        _ = FocusWidgetBundle.sharedDefaultsToken
    }

    // MARK: Body

    internal var body: some Widget {
        FocusWidget()
    }
}
