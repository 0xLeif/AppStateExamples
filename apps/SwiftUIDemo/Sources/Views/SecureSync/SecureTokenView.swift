import SwiftUI
import AppState

// MARK: - Secure Token View

/// Demonstrates `@SecureState` — a `String?` backed by the system Keychain.
internal struct SecureTokenView: View {

    // MARK: State

    @SecureState(\.apiToken) private var apiToken: String?

    @State private var tokenDraft: String = ""
    @State private var isRevealed: Bool = false

    // MARK: Body

    internal var body: some View {
        Form {
            Section {
                if isRevealed {
                    TextField("API Token", text: $tokenDraft)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .accessibilityIdentifier("TokenField")
                } else {
                    SecureField("API Token", text: $tokenDraft)
                        .accessibilityIdentifier("TokenSecureField")
                }

                Toggle("Reveal token", isOn: $isRevealed)
                    .accessibilityIdentifier("RevealTokenToggle")
            } header: {
                Text("Token Storage")
            } footer: {
                Text(
                    "Written to and read from the system Keychain. "
                        + "The value is never stored in UserDefaults or on disk in plain text."
                )
            }

            Section {
                Button("Save Token") {
                    apiToken = tokenDraft.isEmpty ? nil : tokenDraft
                }
                .accessibilityIdentifier("SaveTokenButton")

                if apiToken != nil {
                    Button("Delete Token", role: .destructive) {
                        apiToken = nil
                        tokenDraft = ""
                    }
                    .accessibilityIdentifier("DeleteTokenButton")
                }
            }

            Section("Current Keychain Value") {
                if let savedToken = apiToken {
                    Text(isRevealed ? savedToken : String(repeating: "•", count: min(savedToken.count, 16)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("TokenCurrentValue")
                } else {
                    Text("(no token stored)")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("TokenCurrentValue")
                }
            }
        }
        .navigationTitle("API Token (@SecureState)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            tokenDraft = apiToken ?? ""
        }
    }
}
