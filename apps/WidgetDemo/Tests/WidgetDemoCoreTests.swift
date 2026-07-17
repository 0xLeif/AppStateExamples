import Foundation
import XCTest
import AppState
import WidgetKit
@testable import WidgetDemoCore

// MARK: - Widget Core Tests

/// Behavioral coverage for shared storage, timeline entries, and provider callbacks.
@MainActor
internal final class WidgetDemoCoreTests: XCTestCase {
    internal func testFocusEntryAndPlaceholderValues() {
        let date = Date(timeIntervalSince1970: 1_234)
        let entry = FocusEntry(date: date, focusTitle: "Deep Work", focusCount: 8)

        XCTAssertEqual(entry.date, date)
        XCTAssertEqual(entry.focusTitle, "Deep Work")
        XCTAssertEqual(entry.focusCount, 8)
        XCTAssertEqual(FocusEntry.placeholder.focusTitle, "Focus Session")
        XCTAssertEqual(FocusEntry.placeholder.focusCount, 0)
    }

    internal func testAppGroupDefaultsWrapperRoundTripsAndRemovesValues() {
        let suiteName = "WidgetDemoCoreTests.\(UUID().uuidString)"
        let defaults = AppGroupUserDefaults(suiteName: suiteName)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        defaults.set("value", forKey: "key")
        XCTAssertEqual(defaults.object(forKey: "key") as? String, "value")
        defaults.removeObject(forKey: "key")
        XCTAssertNil(defaults.object(forKey: "key"))
    }

    internal func testStoredStateAndCurrentEntryRoundTripValues() {
        var title = Application.storedState(\.focusTitle)
        title.value = "Release Review"
        var count = Application.storedState(\.focusCount)
        count.value = 12

        let entry = FocusTimelineSource().currentEntry()
        XCTAssertEqual(entry.focusTitle, "Release Review")
        XCTAssertEqual(entry.focusCount, 12)
    }

    internal func testSharedDefaultsOverrideCanBeInstalledAndCancelled() async {
        let token = Application.useSharedDefaults()
        XCTAssertNotNil(token)
        await token?.cancel()
    }

    internal func testProviderBuildsCurrentEntryAndNeverRefreshTimeline() {
        var title = Application.storedState(\.focusTitle)
        title.value = "Timeline Work"
        var count = Application.storedState(\.focusCount)
        count.value = 5
        let provider = FocusTimelineSource()
        let entry = provider.currentEntry()
        XCTAssertEqual(entry.focusTitle, "Timeline Work")
        XCTAssertEqual(entry.focusCount, 5)

        let timeline = provider.currentTimeline()
        XCTAssertEqual(timeline.entries.count, 1)
        XCTAssertEqual(timeline.entries.first?.focusTitle, "Timeline Work")
        switch timeline.policy {
        case .never:
            break
        default:
            XCTFail("Expected a never-refresh timeline")
        }
    }

    internal func testProviderDeliveryCallbacksUseCurrentState() async {
        var title = Application.storedState(\.focusTitle)
        title.value = "Callback Work"
        var count = Application.storedState(\.focusCount)
        count.value = 9
        let provider = FocusTimelineSource()

        let snapshotExpectation = expectation(description: "snapshot delivery")
        provider.deliverSnapshot { entry in
            XCTAssertEqual(entry.focusTitle, "Callback Work")
            XCTAssertEqual(entry.focusCount, 9)
            snapshotExpectation.fulfill()
        }

        let timelineExpectation = expectation(description: "timeline delivery")
        provider.deliverTimeline { timeline in
            XCTAssertEqual(timeline.entries.first?.focusTitle, "Callback Work")
            XCTAssertEqual(timeline.entries.first?.focusCount, 9)
            timelineExpectation.fulfill()
        }

        await fulfillment(of: [snapshotExpectation, timelineExpectation], timeout: 2)
    }
}
