import SwiftUI
import XCTest
import AppState
import SnapshotTesting
import WidgetKit
import WidgetDemoCore
@testable import WidgetDemo

// MARK: - Widget Snapshot Tests

/// Image regression coverage for the host editor and every supported widget family.
@MainActor
internal final class WidgetDemoSnapshotTests: XCTestCase {
    internal func testEditorInitialState() {
        seed(title: "Focus Session", count: 0)
        assertScreenSnapshot(of: FocusEditorView(), named: "editor-initial")
    }

    internal func testEditorProgressState() {
        seed(title: "Ship the AppState 3 examples", count: 7)
        assertScreenSnapshot(of: FocusEditorView(), named: "editor-progress")
    }

    internal func testSmallWidgetLightAndDark() {
        let entry = FocusEntry(date: .now, focusTitle: "Deep Work", focusCount: 4)
        assertDefaultWidgetSnapshot(entry: entry, named: "small-environment-default")
        assertWidgetSnapshot(entry: entry, family: .systemSmall, colorScheme: .light, named: "small-light")
        assertWidgetSnapshot(entry: entry, family: .systemSmall, colorScheme: .dark, named: "small-dark")
    }

    internal func testMediumWidgetLightAndDark() {
        let entry = FocusEntry(date: .now, focusTitle: "Release verification", focusCount: 12)
        assertWidgetSnapshot(entry: entry, family: .systemMedium, colorScheme: .light, named: "medium-light")
        assertWidgetSnapshot(entry: entry, family: .systemMedium, colorScheme: .dark, named: "medium-dark")
    }

    internal func testUnsupportedFamilyFallsBackToSmallLayout() {
        let entry = FocusEntry(date: .now, focusTitle: "Fallback", focusCount: 1)
        assertWidgetSnapshot(entry: entry, family: .systemLarge, colorScheme: .light, named: "fallback-large")
    }

    private func seed(title: String, count: Int) {
        var titleState = Application.storedState(\.focusTitle)
        titleState.value = title
        var countState = Application.storedState(\.focusCount)
        countState.value = count
    }

    private func assertScreenSnapshot<Content: View>(of view: Content, named name: String) {
        assertSnapshot(
            of: view,
            as: .image(
                layout: .device(config: .iPhone13),
                traits: UITraitCollection(userInterfaceStyle: .light)
            ),
            named: name,
            record: .missing
        )
    }

    private func assertWidgetSnapshot(
        entry: FocusEntry,
        family: WidgetFamily,
        colorScheme: ColorScheme,
        named name: String
    ) {
        let size = family == .systemMedium
            ? CGSize(width: 360, height: 170)
            : CGSize(width: 170, height: 170)
        let view = FocusWidgetView(entry: entry, family: family)
            .environment(\.colorScheme, colorScheme)

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: size.width, height: size.height),
                traits: UITraitCollection(
                    userInterfaceStyle: colorScheme == .dark ? .dark : .light
                )
            ),
            named: name,
            record: .missing
        )
    }

    private func assertDefaultWidgetSnapshot(entry: FocusEntry, named name: String) {
        assertSnapshot(
            of: FocusWidgetView(entry: entry),
            as: .image(
                layout: .fixed(width: 170, height: 170),
                traits: UITraitCollection(userInterfaceStyle: .light)
            ),
            named: name,
            record: .missing
        )
    }
}
