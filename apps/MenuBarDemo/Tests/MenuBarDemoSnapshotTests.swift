import AppKit
import SwiftUI
import XCTest
import AppState
import SnapshotTesting
@testable import MenuBarDemo

// MARK: - Menu Bar Snapshot Tests

/// Image regression coverage for the complete popover and meaningful state variants.
@MainActor
internal final class MenuBarDemoSnapshotTests: XCTestCase {
    internal func testCompletePopover() {
        seed(count: 3, greeting: "Ship AppState 3", accent: "Purple")
        assertViewSnapshot(
            of: MenuBarPopoverView(secureTokenPresentation: .fixture(nil)),
            size: CGSize(width: 340, height: 600),
            named: "complete-popover"
        )
    }

    internal func testSecureFixtureAndDependencySections() {
        seed(count: 0, greeting: "Dependency ready", accent: "Blue")
        let view = VStack(alignment: .leading, spacing: 0) {
            SecureTokenSectionView(presentation: .fixture("secret-token"))
            Divider()
            DependencySectionView()
        }
        .frame(width: 340)

        assertViewSnapshot(
            of: view,
            size: CGSize(width: 340, height: 270),
            named: "secure-and-dependency"
        )
    }

    internal func testAllAccentColorsAndSharedComponents() {
        seed(count: 3, greeting: "Ship AppState 3", accent: "Purple")
        let names = ["Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Teal", "Unknown"]
        for name in names {
            var accent = Application.syncState(\.accentName)
            accent.value = name
            assertViewSnapshot(
                of: AccentSyncSectionView(),
                size: CGSize(width: 340, height: 125),
                named: "accent-\(name.lowercased())"
            )
        }

        assertViewSnapshot(
            of: SectionHeaderView(
                title: "AppState 3",
                subtitle: "Verified reusable menu-bar component"
            )
            .padding(),
            size: CGSize(width: 340, height: 90),
            named: "section-header"
        )
    }

    private func seed(count: Int, greeting: String, accent: String) {
        var countState = Application.state(\.clickCount)
        countState.value = count
        var greetingState = Application.storedState(\.greeting)
        greetingState.value = greeting
        var accentState = Application.syncState(\.accentName)
        accentState.value = accent
    }

    private func assertViewSnapshot<Content: View>(of view: Content, size: CGSize, named name: String) {
        let snapshotView = view
            .frame(width: size.width, height: size.height)
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, .light)
        let hostingView = NSHostingView(rootView: snapshotView)
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.appearance = NSAppearance(named: .aqua)
        hostingView.layoutSubtreeIfNeeded()

        assertSnapshot(of: hostingView, as: .image(size: size), named: name, record: .missing)
    }
}
