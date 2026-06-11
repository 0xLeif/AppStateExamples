import SwiftUI
import AppState

// MARK: - Greeting View

/// Shows `@AppDependency` resolving a `GreetingProviding` service,
/// and demonstrates `Application.override` to hot-swap the implementation.
internal struct GreetingView: View {

    // MARK: Dependencies

    @AppDependency(\.greetingService) private var greetingService: any GreetingProviding

    // MARK: State

    @AppState(\.username) private var username: String

    /// Token that keeps the mock override alive until cancelled.
    @State private var overrideToken: Application.DependencyOverride? = nil

    // MARK: Body

    internal var body: some View {
        Form {
            Section("Result") {
                Text(greetingService.greet(username))
                    .font(.title3)
                    .accessibilityIdentifier("GreetingOutput")
            }

            Section("Active Implementation") {
                LabeledContent(
                    "Service",
                    value: overrideToken != nil ? "MockGreetingService" : "LiveGreetingService"
                )
                .accessibilityIdentifier("ActiveServiceLabel")
            }

            Section {
                if overrideToken == nil {
                    Button("Swap in MockGreetingService") {
                        overrideToken = Application.override(
                            \.greetingService,
                            with: MockGreetingService()
                        )
                    }
                    .accessibilityIdentifier("SwapToMockButton")
                } else {
                    Button("Restore LiveGreetingService") {
                        Task { @MainActor in
                            await overrideToken?.cancel()
                            overrideToken = nil
                        }
                    }
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("RestoreLiveButton")
                }
            } header: {
                Text("Override")
            } footer: {
                Text("`Application.override` is the same mechanism used in unit tests — the token cancels the override when it goes out of scope.")
            }
        }
        .navigationTitle("Greeting Service")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
