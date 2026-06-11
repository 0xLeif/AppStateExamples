import SwiftUI

// MARK: - SectionHeaderView

/// A reusable header used atop each feature section in the menu-bar popover.
internal struct SectionHeaderView: View {

    // MARK: Properties

    /// The primary label, typically the AppState property-wrapper name.
    internal let title: String

    /// A brief description of the state type being demonstrated.
    internal let subtitle: String

    // MARK: Body

    internal var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.bold().monospaced())
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
