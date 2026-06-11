import SwiftUI
import AppState

// MARK: - CounterSectionView

/// Demonstrates `@AppState` — an in-memory integer counter.
///
/// The count is also reflected in the menu-bar icon title so changes are
/// immediately visible without opening the popover.
internal struct CounterSectionView: View {

    // MARK: State

    @AppState(\.clickCount) private var clickCount: Int

    // MARK: Body

    internal var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderView(
                title: "@AppState",
                subtitle: "In-memory integer — live in the menu-bar title"
            )

            HStack {
                Text("Count:")
                    .foregroundStyle(.secondary)
                Text("\(clickCount)")
                    .font(.title2.monospacedDigit().bold())
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: clickCount)

                Spacer()

                Button {
                    clickCount += 1
                } label: {
                    Label("Increment", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Button {
                    clickCount = 0
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
