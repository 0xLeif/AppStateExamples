import WidgetKit
import AppState

// MARK: - Focus Timeline Source

/// Reads AppState 3 shared values and supplies entries to the WidgetKit protocol adapter.
public struct FocusTimelineSource: Sendable {
    /// Creates a source backed by the current shared AppState values.
    public init() {}

    /// Bridges WidgetKit's snapshot callback to the main-actor AppState read.
    public func deliverSnapshot(_ completion: @escaping (FocusEntry) -> Void) {
        let sendableCompletion = UncheckedSendable(completion)
        Task { @MainActor in
            sendableCompletion.value(currentEntry())
        }
    }

    /// Bridges WidgetKit's timeline callback to the main-actor AppState read.
    public func deliverTimeline(_ completion: @escaping (Timeline<FocusEntry>) -> Void) {
        let sendableCompletion = UncheckedSendable(completion)
        Task { @MainActor in
            sendableCompletion.value(currentTimeline())
        }
    }

    /// Reads the current shared StoredState values and wraps them in a `FocusEntry`.
    @MainActor
    internal func currentEntry() -> FocusEntry {
        let title = Application.storedState(\.focusTitle).value
        let count = Application.storedState(\.focusCount).value
        return FocusEntry(date: .now, focusTitle: title, focusCount: count)
    }

    /// Creates the never-refreshing timeline used by WidgetKit callbacks.
    @MainActor
    internal func currentTimeline() -> Timeline<FocusEntry> {
        // The host app calls `WidgetCenter.shared.reloadAllTimelines()` on every mutation,
        // so an automatic refresh policy is unnecessary and wastes resources.
        Timeline(entries: [currentEntry()], policy: .never)
    }
}

// MARK: - Unchecked Sendable Box

/// Wraps WidgetKit's non-Sendable callback while crossing into a main-actor task.
/// WidgetKit guarantees these callbacks are invoked once from a single execution path.
private struct UncheckedSendable<Value>: @unchecked Sendable {
    internal let value: Value

    internal init(_ value: Value) {
        self.value = value
    }
}
