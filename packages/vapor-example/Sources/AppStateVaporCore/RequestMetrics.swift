import Foundation

// MARK: - RequestMetrics

/// Thread-safe, in-memory store for per-route request counts.
///
/// Implemented as an `actor` so callers on any concurrency context — including
/// Vapor's EventLoop-isolated route handlers — can safely increment counters
/// without hopping to the main thread.  This is intentionally separate from
/// the `State<Int>`-based `totalRequestCount`, which requires a main-thread hop.
/// Use both to demonstrate the two patterns side by side.
public actor RequestMetrics: Sendable {
    // MARK: - Private Storage

    private var counters: [String: Int] = [:]

    // MARK: - Initializer

    /// Creates a fresh `RequestMetrics` with all counters at zero.
    public init() {}

    // MARK: - Public Interface

    /// Records a hit for the given route label.
    ///
    /// - Parameter route: A canonical route label, e.g. `"GET /"`.
    public func record(route: String) {
        counters[route, default: 0] += 1
    }

    /// Returns the hit count for a specific route, or `0` if never recorded.
    ///
    /// - Parameter route: The route label to look up.
    public func count(for route: String) -> Int {
        counters[route, default: 0]
    }

    /// A snapshot of all recorded counters, safe to serialise.
    public var snapshot: [String: Int] {
        counters
    }

    /// Resets all counters to zero.  Useful in tests.
    public func reset() {
        counters = [:]
    }
}
