import SwiftUI
import AppState

// MARK: - Observed Counter View

/// Demonstrates `@ObservedDependency` with a `LiveCounterService` that conforms
/// to `ObservableObject`. Every time `service.ticks` changes, SwiftUI re-renders
/// this view — driven by `@Published` inside the service, not by AppState's own
/// observation machinery.
internal struct ObservedCounterView: View {

    // MARK: Dependencies

    @ObservedDependency(\.counterService) private var service: LiveCounterService

    // MARK: Body

    internal var body: some View {
        Form {
            Section("Ticks") {
                HStack {
                    Text("Service ticks")
                    Spacer()
                    Text("\(service.ticks)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("ServiceTicksValue")
                }
            }

            Section {
                Button("Tick (+1)") {
                    service.tick()
                }
                .accessibilityIdentifier("TickButton")

                Button("Reset", role: .destructive) {
                    service.reset()
                }
                .accessibilityIdentifier("ResetServiceButton")
            } footer: {
                Text(
                    """
                    The service is a shared singleton via `@AppDependency`/`@ObservedDependency` — \
                    its state persists as long as the app runs.
                    """
                )
            }
        }
        .navigationTitle("Observable Service")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
