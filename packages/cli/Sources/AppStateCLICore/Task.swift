import Foundation

// MARK: - TodoItem

/// A single trackable work item.
public struct TodoItem: Codable, Sendable, Equatable {
    /// Unique identifier for the item.
    public let id: String

    /// Human-readable title describing the work.
    public var title: String

    /// Whether this item has been marked as complete.
    public var isCompleted: Bool

    /// Wall-clock date when the item was created.
    public let createdAt: Date

    /// Creates a new `TodoItem`.
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - title: Human-readable description.
    ///   - isCompleted: Completion state; defaults to `false`.
    ///   - createdAt: Creation timestamp.
    public init(id: String, title: String, isCompleted: Bool = false, createdAt: Date) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}
