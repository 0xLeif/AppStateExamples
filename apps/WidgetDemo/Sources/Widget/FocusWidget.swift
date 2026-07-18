import WidgetKit
import SwiftUI
import WidgetDemoCore

// MARK: - Focus Widget

/// A WidgetKit widget that displays the current focus session title and count.
/// Supports `.systemSmall` and `.systemMedium` families.
internal struct FocusWidget: Widget {

    // MARK: Properties

    internal let kind: String = "FocusWidget"

    // MARK: Configuration

    internal var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusTimelineProvider()) { entry in
            FocusWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus Session")
        .description("Shows your current focus session title and completed increments.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
