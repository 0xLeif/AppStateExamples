import SwiftUI
import AppState

// MARK: - Username View

/// Demonstrates `@StoredState` backed by `UserDefaults`.
/// The value survives app restarts.
internal struct UsernameView: View {

    // MARK: State

    @StoredState(\.username) private var username: String

    // MARK: Body

    internal var body: some View {
        Form {
            Section {
                TextField("Username", text: $username)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .accessibilityIdentifier("UsernameField")
            } header: {
                Text("Display Name")
            } footer: {
                Text("Persisted to `UserDefaults` — survives process restarts.")
            }

            Section {
                LabeledContent("Current value", value: username.isEmpty ? "(empty)" : username)
                    .foregroundStyle(username.isEmpty ? .secondary : .primary)
            }

            Section {
                Button("Clear") {
                    username = ""
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Username (@StoredState)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
