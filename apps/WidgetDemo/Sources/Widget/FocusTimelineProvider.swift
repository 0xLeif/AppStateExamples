import WidgetKit
import AppState

// MARK: - Focus Timeline Provider

/// Reads `focusTitle` and `focusCount` from the shared App Group `UserDefaults`
/// (via AppState `StoredState`) and supplies timeline entries to WidgetKit.
///
/// The shared-defaults override must already be installed before any method on
/// this provider is called — `FocusWidgetBundle.init()` guarantees that.
internal struct FocusTimelineProvider: TimelineProvider {

    // MARK: TimelineProvider

    internal func placeholder(in context: Context) -> FocusEntry {
        FocusEntry.placeholder
    }

    internal func getSnapshot(in context: Context, completion: @escaping (FocusEntry) -> Void) {
        let sendableCompletion = UncheckedSendable(completion)
        Task { @MainActor in
            sendableCompletion.value(currentEntry())
        }
    }

    internal func getTimeline(in context: Context, completion: @escaping (Timeline<FocusEntry>) -> Void) {
        let sendableCompletion = UncheckedSendable(completion)
        Task { @MainActor in
            let entry = currentEntry()
            // `.never` policy means WidgetKit will not automatically refresh the timeline.
            // The host app calls `WidgetCenter.shared.reloadAllTimelines()` on every mutation,
            // so an automatic refresh policy is unnecessary and wastes resources.
            let timeline = Timeline(entries: [entry], policy: .never)
            sendableCompletion.value(timeline)
        }
    }

    // MARK: Private Helpers

    /// Reads the current shared StoredState values and wraps them in a `FocusEntry`.
    @MainActor
    private func currentEntry() -> FocusEntry {
        let title = Application.state(\.focusTitle).value
        let count = Application.state(\.focusCount).value
        return FocusEntry(date: .now, focusTitle: title, focusCount: count)
    }
}

// MARK: - Unchecked Sendable Box

/// Wraps a non-`Sendable` value in a `@unchecked Sendable` box.
///
/// Used sparingly to bridge WidgetKit completion-handler closures (which WidgetKit
/// guarantees are called once, from a single thread) into Swift 6 strict concurrency.
private struct UncheckedSendable<Value>: @unchecked Sendable {
    internal let value: Value
    internal init(_ value: Value) { self.value = value }
}
