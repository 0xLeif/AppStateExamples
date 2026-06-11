import AppState
import Observation
import Foundation

// MARK: - ObservationDemo

/// Demonstrates AppState 3.0's headless observation feature.
///
/// `Application` is `@Observable`, so `withObservationTracking` works without
/// SwiftUI. The `onChange` closure fires once per change; re-arming inside it
/// keeps the observation alive across multiple mutations.
public enum ObservationDemo: Sendable {

    // MARK: - run

    /// Runs a self-contained watch demo that mutates `selectedItemIndex` a
    /// fixed number of times, awaiting each observation cycle before the
    /// next mutation so that every `onChange` is captured.
    ///
    /// All work happens on the main actor, which AppState requires. The
    /// function is `async` so callers can `await` its completion.
    ///
    /// - Parameters:
    ///   - mutationCount: Number of mutations to perform (default 5).
    ///   - output: Closure called for each line of output.
    @MainActor
    public static func run(
        mutationCount: Int = 5,
        output: @escaping @Sendable (String) -> Void
    ) async {
        output("--- Headless Observation Demo ---")
        output("Watching `selectedItemIndex` for \(mutationCount) mutations...")

        for step in 1...mutationCount {
            let newValue = step % 3 == 0 ? nil : Optional(step)

            // Arm tracking before the mutation.
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                withObservationTracking {
                    // Register this tracking scope over selectedItemIndex.
                    _ = Application.state(\.selectedItemIndex).value
                } onChange: {
                    // Fires synchronously when the value changes below.
                    // Schedule reading/reporting on the main actor, then
                    // resume the continuation so the loop can proceed.
                    _Concurrency.Task { @MainActor in
                        let current = Application.state(\.selectedItemIndex).value
                        let display = current.map { "\($0)" } ?? "nil"
                        output("  onChange [\(step)/\(mutationCount)]: selectedItemIndex -> \(display)")
                        continuation.resume()
                    }
                }

                // Mutate after arming so the tracking scope is live.
                var selectionState = Application.state(\.selectedItemIndex)
                selectionState.value = newValue
            }
        }

        output("--- Observation demo complete ---")
    }
}
