import AppState
import Foundation
import Observation

// MARK: - One-shot Observation

/// Registers a one-shot `withObservationTracking` scope that calls `onChange`
/// exactly once, then stops.
///
/// This is the raw building block that `StateObserver` and `ObservationStream`
/// are built on top of. Useful when you need a single reaction without continuous
/// re-arming — e.g. "wake me up the next time X changes."
///
/// - Parameters:
///   - read: Closure that reads the state value, registering the dependency.
///   - onChange: Called once after the next mutation to the observed state.
@MainActor
public func observeOnce<Value>(
    _ read: @escaping @MainActor () -> Value,
    onChange: @escaping @MainActor (Value) -> Void
) {
    withObservationTracking {
        _ = read()
    } onChange: {
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                onChange(read())
            }
        }
    }
}

// MARK: - Multi-observer Broadcast Tracker

/// Tracks how many distinct observers fired in response to a single mutation.
///
/// This type is used by the demo and tests to verify that registering N independent
/// `withObservationTracking` scopes against the same state causes all N `onChange`
/// callbacks to fire when the state changes.
@MainActor
public final class BroadcastTracker {

    // MARK: - Properties

    /// The total number of `onChange` callbacks received across all registered observers.
    public private(set) var fireCount: Int = 0

    /// The set of observer labels that have fired at least once.
    public private(set) var firedLabels: [String] = []

    // MARK: - Initializer

    /// Creates a new `BroadcastTracker`.
    public init() {}

    // MARK: - Public Methods

    /// Registers a new observer against the provided `read` closure.
    /// Each observer is one-shot by design; call `register` again to re-arm.
    ///
    /// - Parameters:
    ///   - label: A human-readable label stored in `firedLabels` on fire.
    ///   - read: Closure that reads the state, registering the Observation dependency.
    public func register(label: String, read: @escaping @MainActor () -> some Sendable) {
        withObservationTracking {
            _ = read()
        } onChange: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.fireCount += 1
                    self.firedLabels.append(label)
                }
            }
        }
    }

    /// Resets all counters.
    public func reset() {
        fireCount = 0
        firedLabels.removeAll()
    }
}

// MARK: - Async Observation Utilities

/// Waits until an `AsyncStream` yields `count` elements and returns them.
///
/// Useful in tests and demos to drain a fixed number of stream values without
/// consuming the whole stream or requiring a manual break.
///
/// - Parameters:
///   - stream: The `AsyncStream` to drain.
///   - count: The number of elements to collect.
/// - Returns: An array of the first `count` elements.
public func collect<Value: Sendable>(
    _ stream: AsyncStream<Value>,
    count: Int
) async -> [Value] {
    var results: [Value] = []
    results.reserveCapacity(count)
    for await value in stream {
        results.append(value)
        if results.count >= count {
            break
        }
    }
    return results
}
