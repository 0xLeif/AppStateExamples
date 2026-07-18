import SwiftUI
import AppState

// MARK: - Secure Token Presentation

/// Selects live Keychain data in production or a deterministic value in previews and snapshots.
internal enum SecureTokenPresentation: Sendable, Equatable {
    case live
    case fixture(String?)
}


// MARK: - SecureTokenSectionView

/// Introduces the `@SecureState` example without reading the login Keychain on launch.
internal struct SecureTokenSectionView: View {

    // MARK: - Properties

    private let presentation: SecureTokenPresentation

    // MARK: - State

    @State private var isKeychainAccessEnabled: Bool = false

    // MARK: - Initializer

    /// Creates a secure-token section.
    /// - Parameter presentation: Uses opt-in live Keychain access by default; tests provide an in-memory fixture.
    internal init(presentation: SecureTokenPresentation = .live) {
        self.presentation = presentation
    }

    // MARK: - Body

    @ViewBuilder
    internal var body: some View {
        switch presentation {
        case .live:
            if isKeychainAccessEnabled {
                LiveSecureTokenEditorView()
            } else {
                SecureTokenOptInView {
                    isKeychainAccessEnabled = true
                }
            }
        case .fixture(let token):
            FixtureSecureTokenEditorView(token: token)
        }
    }
}


// MARK: - Opt-In View

/// Explains system Keychain access before the live property wrapper is created.
private struct SecureTokenOptInView: View {

    // MARK: - Properties

    private let enableAccess: () -> Void

    // MARK: - Initializer

    fileprivate init(enableAccess: @escaping () -> Void) {
        self.enableAccess = enableAccess
    }

    // MARK: - Body

    fileprivate var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderView(
                title: "@SecureState",
                subtitle: "Login Keychain — access is off until you enable this demo"
            )

            Label("This app has not accessed your Keychain.", systemImage: "lock.shield")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Enable Keychain Demo", action: enableAccess)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityIdentifier("EnableKeychainDemoButton")

            Text("macOS may request your login password when an older local build created the saved item.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}


// MARK: - Live Storage

/// Owns the live property wrapper only after the user opts in to Keychain access.
private struct LiveSecureTokenEditorView: View {

    // MARK: - State

    @SecureState(\.apiToken) private var apiToken: String?

    // MARK: - Body

    fileprivate var body: some View {
        SecureTokenEditorView(token: $apiToken)
    }
}


// MARK: - Fixture Storage

/// Keeps snapshot and unit-test values in memory so automated tests never touch the Keychain.
private struct FixtureSecureTokenEditorView: View {

    // MARK: - State

    @State private var token: String?

    // MARK: - Initializer

    fileprivate init(token: String?) {
        _token = State(initialValue: token)
    }

    // MARK: - Body

    fileprivate var body: some View {
        SecureTokenEditorView(token: $token)
    }
}


// MARK: - Token Editor

/// Edits either the live Keychain value or an in-memory test fixture through the same UI.
private struct SecureTokenEditorView: View {

    // MARK: - State

    @Binding private var token: String?
    @State private var tokenDraft: String = ""
    @State private var isRevealed: Bool = false

    // MARK: - Initializer

    fileprivate init(token: Binding<String?>) {
        _token = token
    }

    // MARK: - Body

    fileprivate var body: some View {
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
                    token = tokenDraft.isEmpty ? nil : tokenDraft
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                if token != nil {
                    Button("Clear", role: .destructive) {
                        token = nil
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
            tokenDraft = token ?? ""
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var keychainStatusBadge: some View {
        if let token {
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
