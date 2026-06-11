// MARK: - TodoItem

/// A lightweight, value-typed to-do entry.
///
/// `Sendable` and `Equatable` so it can safely cross concurrency boundaries
/// and be compared during observation-triggered re-renders.
public struct TodoItem: Sendable, Equatable {
    /// Stable identifier generated at insertion time.
    public let id: Int

    /// User-supplied text for this item.
    public var text: String

    /// Creates a new `TodoItem`.
    /// - Parameters:
    ///   - id: Monotonically increasing integer assigned by the store.
    ///   - text: Display text.
    public init(id: Int, text: String) {
        self.id = id
        self.text = text
    }
}
