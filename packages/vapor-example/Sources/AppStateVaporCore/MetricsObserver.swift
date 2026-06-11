import AppState
import Foundation
import Observation

// MARK: - MetricsObserver

/// A headless observer that watches `Application.totalRequestCount` via
/// `withObservationTracking` and logs every time the value changes.
///
/// This demonstrates AppState 3.0's **observation without SwiftUI** — the
/// same `@Observable`-driven tracking works in a pure server-side context.
///
/// ## How it works
///
/// 1. `start()` calls `armTracking()`, which reads
///    `Application.state(\.totalRequestCount).value` inside a
///    `withObservationTracking` block.  That read registers the current
///    observation scope as a dependency.
/// 2. When any code mutates `totalRequestCount` on the main thread, the
///    `onChange` closure fires **once**, synchronously.
/// 3. `onChange` re-arms by calling `armTracking()` again, creating a
///    continuous observation loop.
///
/// ## Threading note
///
/// `onChange` always fires on the main thread (AppState's contract).
/// `MetricsObserver` itself is `@MainActor`-isolated to make that explicit.
@MainActor
public final class MetricsObserver: Sendable {
    // MARK: - Private State

    private let label: String

    // MARK: - Initializer

    /// Creates a new observer.
    ///
    /// - Parameter label: Prefix string written to stdout on each change event.
    public init(label: String = "[MetricsObserver]") {
        self.label = label
    }

    // MARK: - Public Interface

    /// Begins the observation loop.
    ///
    /// Safe to call multiple times — each call arms exactly one tracking pass.
    public func start() {
        armTracking()
    }

    // MARK: - Private Helpers

    /// Arms a single `withObservationTracking` pass.
    ///
    /// Reading `totalRequestCount.value` inside the tracking block registers
    /// `Application.shared` as the observed dependency.  The `onChange`
    /// closure is scheduled for **one** invocation on the next mutation, then
    /// discarded — re-arming here keeps observation continuous.
    private func armTracking() {
        withObservationTracking {
            // Registering the read — return value intentionally unused.
            _ = Application.state(\.totalRequestCount).value
        } onChange: { [weak self] in
            // `onChange` fires on the main thread, once, synchronously.
            // Re-arm immediately so the next change is also captured.
            MainActor.assumeIsolated {
                self?.handleChange()
            }
        }
    }

    private func handleChange() {
        let current = Application.state(\.totalRequestCount).value
        print("\(label) totalRequestCount changed → \(current)")
        // Re-arm for the next change.
        armTracking()
    }
}
