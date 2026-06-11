import SwiftUI

// MARK: - State Section

/// Demonstrates `@AppState`, `@StoredState`, and `@FileState` in a navigable list.
internal struct StateSection: View {

    // MARK: Body

    internal var body: some View {
        NavigationStack {
            List {
                Section("In-Memory (@AppState)") {
                    NavigationLink("Counter") {
                        CounterView()
                    }
                    .accessibilityIdentifier("CounterNavLink")
                }

                Section("UserDefaults (@StoredState)") {
                    NavigationLink("Username") {
                        UsernameView()
                    }
                }

                Section("File System (@FileState)") {
                    NavigationLink("Profile Editor") {
                        ProfileEditorView()
                    }
                }
            }
            .navigationTitle("State")
        }
    }
}
