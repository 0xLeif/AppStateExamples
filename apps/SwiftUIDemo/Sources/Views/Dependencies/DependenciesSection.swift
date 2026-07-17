import SwiftUI

// MARK: - Dependencies Section

/// Demonstrates `@AppDependency`, `Application.override`, and `@ObservedDependency`.
internal struct DependenciesSection: View {

    // MARK: Body

    internal var body: some View {
        NavigationStack {
            List {
                Section("Injected Service (@AppDependency)") {
                    NavigationLink("Greeting Service") {
                        GreetingView()
                    }
                    .accessibilityIdentifier("GreetingNavLink")
                }

                Section("Observable Service (@ObservedDependency)") {
                    NavigationLink("Observable Counter Service") {
                        ObservedCounterView()
                    }
                    .accessibilityIdentifier("ObservedCounterNavLink")
                }

                Section("Apple Integrations") {
                    NavigationLink("Keychain Token (@SecureState)") {
                        SecureTokenView()
                    }
                    .accessibilityIdentifier("SecureTokenNavLink")

                    NavigationLink("iCloud Theme (@SyncState)") {
                        ThemeToggleView()
                    }
                    .accessibilityIdentifier("ThemeNavLink")
                }
            }
            .navigationTitle("Dependencies")
        }
    }
}
