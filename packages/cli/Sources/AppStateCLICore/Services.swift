import Foundation

// MARK: - IDGenerating

/// Produces unique string identifiers for new tasks.
public protocol IDGenerating: Sendable {
    /// Returns a new unique identifier string.
    func newID() -> String
}

// MARK: - Clocking

/// Provides the current wall-clock date, enabling test-time injection.
public protocol Clocking: Sendable {
    /// Returns the current date.
    func now() -> Date
}

// MARK: - Live Implementations

/// Generates UUIDs using `Foundation.UUID`.
public struct UUIDGenerator: IDGenerating {
    /// Creates a new `UUIDGenerator`.
    public init() {}

    public func newID() -> String {
        UUID().uuidString
    }
}

/// Returns the true system time.
public struct SystemClock: Clocking {
    /// Creates a new `SystemClock`.
    public init() {}

    public func now() -> Date {
        Date()
    }
}
