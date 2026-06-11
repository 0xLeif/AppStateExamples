import SwiftUI
import AppState

// MARK: - GreetingSectionView

/// Demonstrates `@StoredState` — a `String` persisted in `UserDefaults`.
///
/// Edits survive app restarts and are immediately visible on next launch.
internal struct GreetingSectionView: View {

    // MARK: State

    @StoredState(\.greeting) private var greeting: String

    // MARK: Body

    internal var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderView(
                title: "@StoredState",
                subtitle: "UserDefaults-backed — survives app restarts"
            )

            TextField("Greeting", text: $greeting)
                .textFieldStyle(.roundedBorder)

            Text("Persisted value: \"\(greeting)\"")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
