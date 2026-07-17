import SwiftUI
import AppState

// MARK: - Counter View

/// Shows `@AppState` with a `Stepper` and explicit reset button.
///
/// The same `counter` key drives the Observability tab's headless panel —
/// mutations here immediately appear in the log there, proving cross-view reactivity.
internal struct CounterView: View {

    // MARK: State

    @AppState(\.counter) private var counter: Int

    // MARK: Body

    internal var body: some View {
        Form {
            Section {
                Stepper(
                    value: $counter,
                    in: -999...999
                ) {
                    HStack {
                        Text("Counter")
                        Spacer()
                        Text("\(counter)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("CounterValue")
                    }
                }
                .accessibilityIdentifier("CounterStepper")
            } footer: {
                Text("Backed by in-memory `Application.counter` — resets when the process exits.")
            }

            Section {
                Button("Reset to Zero") {
                    counter = 0
                }
                .foregroundStyle(.red)
                .accessibilityIdentifier("ResetCounterButton")
            }
        }
        .navigationTitle("Counter (@AppState)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
