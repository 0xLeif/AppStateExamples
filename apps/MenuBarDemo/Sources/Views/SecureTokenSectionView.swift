import SwiftUI
import AppState

// MARK: - Secure Token Presentation

/// Selects live Keychain data in production or a deterministic value in previews and snapshots.
internal enum SecureTokenPresentation: Sendable, Equatable {
    case live
    case fixture(String?)
}

// MARK: - SecureTokenSectionView

/// Demonstrates `@SecureState` — a `String?` backed by the system login Keychain.
///
/// The token is always masked in the UI; only its presence or absence is surfaced.
/// Saving writes to the Keychain; clearing deletes the Keychain entry.
internal struct SecureTokenSectionView: View {

    // MARK: Properties

    private let presentation: SecureTokenPresentation

    // MARK: State

    @SecureState(\.apiToken) private var apiToken: String?

    @State private var tokenDraft: String = ""
    @State private var isRevealed: Bool = false

    // MARK: Initializer

    /// Creates a secure-token section.
    /// - Parameter presentation: Uses the live Keychain by default; tests provide a fixture.
    internal init(presentation: SecureTokenPresentation = .live) {
        self.presentation = presentation
    }

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

                if presentedToken != nil {
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
            tokenDraft = presentedToken ?? ""
        }
    }

    // MARK: Private Views

    @ViewBuilder
    private var keychainStatusBadge: some View {
        if let token = presentedToken {
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

    // MARK: Private Values

    private var presentedToken: String? {
        switch presentation {
        case .live:
            return apiToken
        case .fixture(let token):
            return token
        }
    }
}
