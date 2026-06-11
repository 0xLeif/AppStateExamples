import WidgetKit

// MARK: - Focus Timeline Entry

/// A snapshot of focus session data for a single widget timeline entry.
internal struct FocusEntry: TimelineEntry {

    // MARK: Properties

    /// The date at which this entry is valid.
    internal let date: Date

    /// The user's current focus session title.
    internal let focusTitle: String

    /// The number of completed focus increments.
    internal let focusCount: Int

    // MARK: Initializer

    /// Creates a `FocusEntry` with the given values.
    internal init(date: Date, focusTitle: String, focusCount: Int) {
        self.date = date
        self.focusTitle = focusTitle
        self.focusCount = focusCount
    }
}

// MARK: - Placeholder

extension FocusEntry {

    /// A placeholder entry used while the widget loads real data.
    internal static var placeholder: FocusEntry {
        FocusEntry(date: .now, focusTitle: "Focus Session", focusCount: 0)
    }
}
