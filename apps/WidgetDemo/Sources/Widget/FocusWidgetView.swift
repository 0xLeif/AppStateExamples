import SwiftUI
import WidgetKit

// MARK: - Focus Widget View

/// The visual content of the Focus Widget, rendered from a `FocusEntry`.
/// Adapts its layout for `.systemSmall` and `.systemMedium` families.
internal struct FocusWidgetView: View {

    // MARK: Properties

    internal let entry: FocusEntry

    @Environment(\.widgetFamily) private var widgetFamily

    // MARK: Body

    internal var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallLayout
        case .systemMedium:
            mediumLayout
        default:
            smallLayout
        }
    }

    // MARK: - Layouts

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundStyle(.orange)

            Spacer()

            Text(entry.focusTitle)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Label("\(entry.focusCount)", systemImage: "checkmark.circle.fill")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumLayout: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Focus", systemImage: "timer")
                    .font(.caption)
                    .foregroundStyle(.orange)

                Text(entry.focusTitle)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(spacing: 4) {
                Text("\(entry.focusCount)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.orange)

                Text("increments")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
