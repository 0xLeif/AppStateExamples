import AppState
import Foundation
import Observation

// MARK: - ObservationStream

/// Bridges `withObservationTracking` into an `AsyncStream<Value>` so any caller
/// can use `for await value in stream { ... }` rather than managing manual re-arming.
///
/// ## Why this is useful
/// `withObservationTracking` is a callback-based API that requires explicit re-arming.
/// Wrapping it in `AsyncStream` converts that pattern into idiomatic Swift concurrency,
/// making state changes composable with `async/await` pipelines.
///
/// ## Thread-safety
/// The `read` closure is marked `@MainActor` because all AppState state reads that
/// participate in Observation must occur on the main thread. The `AsyncStream`
/// continuation is `Sendable`, so yielding from the `DispatchQueue.main.async` block
/// is safe.
///
/// ## Cancellation
/// The stream terminates when the `AsyncStream.Continuation` is cancelled (i.e. when
/// the consumer breaks out of the `for await` loop or the task is cancelled).
///
/// ## Usage
/// ```swift
/// let stream = ObservationStream.make(label: "counter") {
///     Application.state(\.counter).value
/// }
/// Task {
///     for await value in stream {
///         print("counter is now \(value)")
///     }
/// }
/// ```
public enum ObservationStream {

    // MARK: - Factory

    /// Creates an `AsyncStream` that yields the current value of a state every time it changes.
    ///
    /// The first element yielded is the current value at subscription time (eager snapshot),
    /// so consumers always receive an initial value before the first mutation.
    ///
    /// - Parameters:
    ///   - label: A label used only for debugging; does not affect stream semantics.
    ///   - bufferingPolicy: The `AsyncStream` buffering policy. Defaults to `.unbounded`.
    ///   - read: A `@MainActor` closure that reads the state value. This closure is called
    ///           inside `withObservationTracking`'s apply block to register the dependency,
    ///           and again on each mutation to read the new value.
    /// - Returns: An `AsyncStream<Value>` that yields a new element on each state change.
    @MainActor
    public static func make<Value: Sendable>(
        label: String = "",
        bufferingPolicy: AsyncStream<Value>.Continuation.BufferingPolicy = .unbounded,
        read: @escaping @MainActor () -> Value
    ) -> AsyncStream<Value> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            // Yield the current value immediately so the consumer has a baseline.
            continuation.yield(read())

            // Start the observation loop.
            arm(read: read, continuation: continuation)
        }
    }

    // MARK: - Private Helpers

    /// Registers one observation scope and re-arms on change until the continuation
    /// signals termination.
    @MainActor
    private static func arm<Value: Sendable>(
        read: @escaping @MainActor () -> Value,
        continuation: AsyncStream<Value>.Continuation
    ) {
        withObservationTracking {
            _ = read()
        } onChange: {
            // Dispatch to main so we read the post-mutation committed value.
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    let newValue = read()
                    let result = continuation.yield(newValue)
                    // Only re-arm if the consumer has not cancelled the stream.
                    switch result {
                    case .enqueued, .dropped:
                        arm(read: read, continuation: continuation)
                    case .terminated:
                        break
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
}
