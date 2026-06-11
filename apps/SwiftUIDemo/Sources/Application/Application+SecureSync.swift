import AppState

// MARK: - Application Secure & Sync Extensions

extension Application {

    // MARK: Keychain State (Apple-only)

    /// A secret API token stored in the device Keychain.
    internal var apiToken: SecureState {
        secureState(id: "apiToken")
    }

    // MARK: iCloud Key-Value Sync State (Apple-only)

    /// The user's preferred colour theme, synchronised across devices via iCloud KV.
    internal var theme: SyncState<String> {
        syncState(initial: "light", id: "theme")
    }
}
