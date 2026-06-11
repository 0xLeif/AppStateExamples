import SwiftUI

// MARK: - Secure & Sync Section

/// Demonstrates `@SecureState` (Keychain) and `@SyncState` (iCloud KV).
/// Both features are Apple-platform-only and require device entitlements;
/// a simulator note is shown so the demo remains informative in all environments.
internal struct SecureSyncSection: View {

    // MARK: Body

    internal var body: some View {
        NavigationStack {
            List {
                Section("Keychain (@SecureState)") {
                    NavigationLink("API Token") {
                        SecureTokenView()
                    }
                }

                Section("iCloud KV (@SyncState)") {
                    NavigationLink("Theme Toggle") {
                        ThemeToggleView()
                    }
                }

                Section {
                    Label(
                        "Keychain requires a signed app with proper entitlements. " +
                        "iCloud sync requires an iCloud-enabled container entitlement. " +
                        "Both work as expected on a physical device or in a signed simulator build.",
                        systemImage: "info.circle"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Secure & Sync")
        }
    }
}
