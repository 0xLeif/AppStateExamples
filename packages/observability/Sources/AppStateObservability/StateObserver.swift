import AppState
import Foundation
import Observation

// MARK: - StateObserver

/// A reusable headless observer that continuously tracks a single `Application` state value
/// and collects a timestamped reaction log.
///
/// ## Design
/// `withObservationTracking` fires its `onChange` closure exactly once per observation
/// registration. `StateObserver` re-arms itself inside `onChange`, producing continuous
/// observation until `stop()` is called or the observer is deallocated.
///
/// ## Thread-safety
/// All state mutations in AppState 3.0 must happen on the main thread.
/// `StateObserver` is therefore `@MainActor`-isolated: its reaction log is only
/// ever read or written on the main thread, removing the need for any manual locking.
///
/// ## Usage
/// ```swift
/// let observer = StateObserver(label: "counter") {
///     Application.state(\.counter).value
/// }
/// observer.start()
/// Application.state(\.counter).value = 1   // fires observer once
/// Application.state(\.counter).value = 2   // fires again after re-arm
/// observer.stop()
/// print(observer.reactionLog)              // ["counter changed: 1", "counter changed: 2"]
/// ```
@MainActor
public final class StateObserver<Value: Sendable> {

    // MARK: - Properties

    /// Human-readable label used in log entries.
    public let label: String

    /// The closure that reads the state value being observed.
    /// Reading the value inside `withObservationTracking`'s apply block registers
    /// the dependency.
    private let read: @MainActor () -> Value

    /// Accumulated reaction log entries, in order of receipt.
    public private(set) var reactionLog: [String] = []

    /// Whether the observer is currently active.
    public private(set) var isObserving: Bool = false

    // MARK: - Initializer

    /// Creates a new `StateObserver`.
    /// - Parameters:
    ///   - label: A human-readable label for log entries.
    ///   - read: A closure that reads the observed state. Called inside the
    ///           `withObservationTracking` apply block on each re-arm.
    public init(label: String, read: @escaping @MainActor () -> Value) {
        self.label = label
        self.read = read
    }

    // MARK: - Public Methods

    /// Begins continuous observation. Safe to call multiple times — subsequent calls
    /// while already observing are no-ops.
    public func start() {
        guard !isObserving else { return }
        isObserving = true
        arm()
    }

    /// Stops continuous observation. The current `onChange` slot (if any) will still
    /// fire once after the next mutation, but no further re-arming will occur.
    public func stop() {
        isObserving = false
    }

    /// Clears the accumulated reaction log.
    public func clearLog() {
        reactionLog.removeAll()
    }

    // MARK: - Private Methods

    /// Registers one `withObservationTracking` scope. Re-arms inside `onChange`
    /// if `isObserving` is still true.
    private func arm() {
        withObservationTracking {
            _ = read()
        } onChange: { [weak self] in
            // onChange fires synchronously on mutation, but `self` access inside
            // onChange runs before the new value is visible. Dispatch async to main
            // so we read the committed, post-mutation value.
            DispatchQueue.main.async { [weak self] in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    let newValue = self.read()
                    let entry = "\(self.label) changed: \(newValue)"
                    self.reactionLog.append(entry)
                    // Re-arm for the next change if still active.
                    if self.isObserving {
                        self.arm()
                    }
                }
            }
        }
    }
}
