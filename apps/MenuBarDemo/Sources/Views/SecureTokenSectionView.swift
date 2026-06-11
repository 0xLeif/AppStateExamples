import SwiftUI
import AppState

// MARK: - SecureTokenSectionView

/// Demonstrates `@SecureState` — a `String?` backed by the system login Keychain.
///
/// The token is always masked in the UI; only its presence or absence is surfaced.
/// Saving writes to the Keychain; clearing deletes the Keychain entry.
internal struct SecureTokenSectionView: View {

    // MARK: State

    @SecureState(\.apiToken) private var apiToken: String?

    @State private var tokenDraft: String = ""
    @State private var isRevealed: Bool = false

    // MARK: Body

    internal var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderView(
                title: "@SecureState",
                subtitle: "Login Keychain — never written to UserDefaults or disk"
            )

            Group {
                if isRevealed {
                    TextField("API Token", text: $tokenDraft)
                        .autocorrectionDisabled()
                } else {
                    SecureField("API Token", text: $tokenDraft)
                }
            }
            .textFieldStyle(.roundedBorder)

            Toggle("Reveal token", isOn: $isRevealed)
                .toggleStyle(.checkbox)

            HStack {
                Button("Save") {
                    apiToken = tokenDraft.isEmpty ? nil : tokenDraft
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                if apiToken != nil {
                    Button("Clear", role: .destructive) {
                        apiToken = nil
                        tokenDraft = ""
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundStyle(.red)
                }

                Spacer()

                keychainStatusBadge
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            tokenDraft = apiToken ?? ""
        }
    }

    // MARK: Private Views

    @ViewBuilder
    private var keychainStatusBadge: some View {
        if let token = apiToken {
            Label(
                String(repeating: "•", count: min(token.count, 8)),
                systemImage: "lock.fill"
            )
            .font(.caption.monospaced())
            .foregroundStyle(.green)
        } else {
            Label("not set", systemImage: "lock.open")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
