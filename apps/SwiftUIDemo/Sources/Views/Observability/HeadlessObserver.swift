import Foundation
import Observation
import AppState

// MARK: - HeadlessObserver

/// A non-SwiftUI observer that uses `withObservationTracking` to react to
/// changes in `Application.counter` — the same counter mutated by `CounterView`
/// in the State tab.
///
/// This proves AppState 3.0's headline feature: `Application` is `@Observable`,
/// so **any** code can participate in Observation without SwiftUI.
///
/// The class is itself `@Observable` only so the `ObservabilitySection` view can
/// render its `log` and `isObserving` reactively — but the observation of
/// `Application.counter` is wired through `withObservationTracking`, not through
/// SwiftUI's body evaluation. The source subscription itself is headless; the
/// class does not conform to `ObservableObject` and uses no Combine publisher.
///
/// `onChange` is one-shot; the observer re-arms itself inside `onChange` for
/// continuous, long-lived observation.
@Observable
@MainActor
internal final class HeadlessObserver {

    // MARK: Properties

    /// A chronological log of every counter-change event captured outside SwiftUI.
    internal private(set) var log: [String] = []

    /// Whether the observer is currently armed and listening.
    internal private(set) var isObserving: Bool = false

    // MARK: Initializer

    internal init() {}

    // MARK: Internal Methods

    /// Starts continuous headless observation of `Application.counter`.
    ///
    /// Safe to call multiple times — a no-op if already observing.
    internal func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        observe()
    }

    /// Stops observation and clears the log.
    internal func stopObserving() {
        isObserving = false
        log = []
    }

    // MARK: Private Methods

    /// Arms one observation tracking cycle. Re-arms itself on change for continuous observation.
    ///
    /// The tracking block reads `Application.counter` directly — this is *headless* observation
    /// because it happens outside a SwiftUI body. `onChange` fires synchronously when the counter
    /// changes, and we re-arm by calling `observe()` again from the main actor.
    private func observe() {
        withObservationTracking {
            // Reading the value registers this call-site as an observer in the Observation graph.
            // This access deliberately happens outside any SwiftUI `body` evaluation.
            _ = Application.state(\.counter).value
        } onChange: { [weak self] in
            // `onChange` fires once, synchronously, on the next counter mutation.
            // Re-arm and update the log on the main actor.
            Task { @MainActor [weak self] in
                guard let self, self.isObserving else { return }
                let newValue = Application.state(\.counter).value
                let entry = "[\(Self.timestamp())] counter → \(newValue)"
                log.append(entry)
                // Keep the log bounded so the list stays responsive.
                if log.count > 50 {
                    log.removeFirst()
                }
                // Re-arm for the next change.
                observe()
            }
        }
    }

    // MARK: Private Helpers

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}
