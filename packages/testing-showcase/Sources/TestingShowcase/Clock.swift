import Foundation

// MARK: - Clock

/// Provides the current time as a Unix epoch integer (seconds since 1970-01-01 UTC).
///
/// Using a protocol instead of `Date.now` directly allows tests to pin time to a
/// known value, making temporal logic fully deterministic.
public protocol Clock: Sendable {
    /// Returns the current time as seconds since the Unix epoch.
    func now() -> Int
}

// MARK: - SystemClock

/// Returns the true system time rounded to the nearest second.
public struct SystemClock: Clock {
    /// Creates a new `SystemClock`.
    public init() {}

    public func now() -> Int {
        Int(Date().timeIntervalSince1970)
    }
}
