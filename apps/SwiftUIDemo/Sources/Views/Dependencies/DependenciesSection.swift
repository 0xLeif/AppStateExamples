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
                }

                Section("Observable Service (@ObservedDependency)") {
                    NavigationLink("Observable Counter Service") {
                        ObservedCounterView()
                    }
                }
            }
            .navigationTitle("Dependencies")
        }
    }
}
