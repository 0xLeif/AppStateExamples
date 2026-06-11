import Foundation
import Combine

// MARK: - LiveCounterService

/// An `ObservableObject` service that holds its own counter, demonstrating
/// `@ObservedDependency` — SwiftUI re-renders whenever `ticks` changes.
internal final class LiveCounterService: ObservableObject, @unchecked Sendable {
    /// Number of ticks accumulated since the service was created.
    @Published internal private(set) var ticks: Int = 0

    /// Creates a new `LiveCounterService`.
    internal init() {}

    /// Increments `ticks` by one. Must be called on the main thread.
    @MainActor
    internal func tick() {
        ticks += 1
    }

    /// Resets `ticks` to zero. Must be called on the main thread.
    @MainActor
    internal func reset() {
        ticks = 0
    }
}
