#if canImport(JavaScriptKit)
import AppState
import Observation
import WASMCore

// MARK: - ObservationLoop

/// Drives continuous re-rendering by re-arming `withObservationTracking` after
/// every state change.
///
/// This is the **headline showcase** of AppState 3.0: `Application` is now
/// `@Observable`, so any read of `Application.state(_:).value` inside the
/// tracking block registers a dependency.  When any tracked state mutates,
/// `onChange` fires once, and a `Task { @MainActor in }` hop schedules a
/// re-render + re-arm — giving us a reactive loop with no SwiftUI required.
///
/// The `onChange` closure itself is **not** `@MainActor`-isolated because it
/// fires synchronously on the thread that performed the mutation.  Work that
/// touches the DOM or `Application` state must be dispatched back to the main
/// actor via `Task { @MainActor in }`.
internal enum ObservationLoop {

    // MARK: - Entry point

    /// Starts the observation loop.  Call exactly once from `main.swift`.
    ///
    /// The loop is self-perpetuating: each `onChange` handler re-calls `arm()`
    /// so the next mutation is also observed.
    @MainActor
    internal static func start() {
        arm()
    }

    // MARK: - Private

    @MainActor
    private static func arm() {
        withObservationTracking {
            // Reading both state values here registers them as tracked
            // dependencies for this observation cycle.  Any write to
            // EITHER value will schedule the `onChange` closure below.
            _ = Application.state(\.counter).value
            _ = Application.state(\.todos).value
        } onChange: {
            // `onChange` is called synchronously on the thread that wrote
            // the value.  We must not call @MainActor code directly here —
            // instead we schedule a Task to hop back to the main actor.
            Task { @MainActor in
                DOMRenderer.render()
                // Re-arm so the NEXT mutation is also observed.
                ObservationLoop.arm()
            }
        }
    }
}
#endif
