import AppState

// MARK: - Application Secure & Sync Extensions

extension Application {

    // MARK: Keychain State (Apple-only)

    /// A secret API token stored in the login Keychain.
    /// Masked in the UI until explicitly revealed by the user.
    internal var apiToken: SecureState {
        secureState(id: "menuBarDemoApiToken")
    }

    // MARK: iCloud Key-Value Sync State (Apple-only)

    /// The user's chosen accent name, synchronised across devices via iCloud KV.
    /// Requires an iCloud-capable signing identity to propagate between devices.
    internal var accentName: SyncState<String> {
        syncState(initial: "Blue", id: "accentName")
    }
}
