import SwiftUI
import AppState

// MARK: - Theme Toggle View

/// Demonstrates `@SyncState` — a `String` stored in `NSUbiquitousKeyValueStore`.
/// Changes propagate to all devices signed into the same iCloud account.
internal struct ThemeToggleView: View {

    // MARK: State

    @SyncState(\.theme) private var theme: String

    // MARK: Computed

    private var isDark: Bool {
        theme == "dark"
    }

    // MARK: Body

    internal var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { isDark },
                    set: { theme = $0 ? "dark" : "light" }
                )) {
                    Label(
                        isDark ? "Dark Mode" : "Light Mode",
                        systemImage: isDark ? "moon.fill" : "sun.max.fill"
                    )
                }
                .accessibilityIdentifier("ThemeToggle")
            } footer: {
                Text("Stored in `NSUbiquitousKeyValueStore` (iCloud Key-Value). Propagates to all devices on the same iCloud account.")
            }

            Section("Current Value") {
                LabeledContent("theme", value: theme)
                    .accessibilityIdentifier("ThemeCurrentValue")
            }
        }
        .navigationTitle("Theme (@SyncState)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
