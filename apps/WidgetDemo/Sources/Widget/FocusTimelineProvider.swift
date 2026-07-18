import WidgetKit
import WidgetDemoCore

// MARK: - Focus Timeline Provider

/// Thin WidgetKit protocol adapter around the fully tested `FocusTimelineSource`.
internal struct FocusTimelineProvider: TimelineProvider, Sendable {

    // MARK: Properties

    private let source: FocusTimelineSource

    // MARK: Initializer

    internal init() {
        self.source = FocusTimelineSource()
    }

    // MARK: TimelineProvider

    internal func placeholder(in context: Context) -> FocusEntry {
        FocusEntry.placeholder
    }

    internal func getSnapshot(in context: Context, completion: @escaping (FocusEntry) -> Void) {
        source.deliverSnapshot(completion)
    }

    internal func getTimeline(in context: Context, completion: @escaping (Timeline<FocusEntry>) -> Void) {
        source.deliverTimeline(completion)
    }
}
