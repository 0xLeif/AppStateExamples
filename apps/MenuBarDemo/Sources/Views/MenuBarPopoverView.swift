import SwiftUI
import AppState

// MARK: - MenuBarPopoverView

/// Root popover content shown when the menu-bar icon is clicked.
///
/// Composes all feature sections and a quit button into a single scrollable form.
internal struct MenuBarPopoverView: View {

    // MARK: Properties

    private let secureTokenPresentation: SecureTokenPresentation

    // MARK: Initializer

    /// Creates the popover with live secure state unless a test fixture is supplied.
    internal init(secureTokenPresentation: SecureTokenPresentation = .live) {
        self.secureTokenPresentation = secureTokenPresentation
    }

    // MARK: Body

    internal var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                CounterSectionView()
                Divider()
                GreetingSectionView()
                Divider()
                SecureTokenSectionView(presentation: secureTokenPresentation)
                Divider()
                AccentSyncSectionView()
                Divider()
                DependencySectionView()
                Divider()
                QuitButtonView()
            }
            .padding(.vertical, 8)
        }
        .frame(width: 340)
        .frame(maxHeight: 600)
    }
}
