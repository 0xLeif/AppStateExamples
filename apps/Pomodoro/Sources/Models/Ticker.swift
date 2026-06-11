import Foundation

// MARK: - Ticker Protocol

/// A service that drives one-second heartbeats into the Pomodoro engine.
///
/// Keeping this behind a protocol lets previews and tests inject a controlled
/// ticker without touching real `Task.sleep` machinery.
internal protocol Ticker: Sendable {

    /// Starts ticking, calling `onTick` once per second until cancelled.
    ///
    /// - Parameter onTick: A `@Sendable` closure executed on the main actor each second.
    /// - Returns: A cancellation token — call `cancel()` to stop the ticker.
    func start(onTick: @escaping @Sendable () async -> Void) -> TickerToken
}

// MARK: - TickerToken

/// An opaque handle returned by `Ticker.start(onTick:)`.
///
/// Callers hold this token and call `cancel()` when the ticker is no longer needed.
internal final class TickerToken: @unchecked Sendable {

    // MARK: Private

    private let task: Task<Void, Never>

    // MARK: Lifecycle

    internal init(task: Task<Void, Never>) {
        self.task = task
    }

    deinit {
        task.cancel()
    }

    // MARK: Internal

    /// Cancels the underlying async task, stopping all future ticks.
    internal func cancel() {
        task.cancel()
    }
}

// MARK: - LiveTicker

/// A real-time ticker that uses `Task.sleep` for one-second intervals.
internal struct LiveTicker: Ticker {

    internal init() {}

    internal func start(onTick: @escaping @Sendable () async -> Void) -> TickerToken {
        let task = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    break
                }
                guard !Task.isCancelled else { break }
                await onTick()
            }
        }
        return TickerToken(task: task)
    }
}
