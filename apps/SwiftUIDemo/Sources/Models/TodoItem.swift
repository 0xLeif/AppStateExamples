#if canImport(SwiftData)
import SwiftData
import Foundation

// MARK: - TodoItem

/// A single to-do item stored via SwiftData.
@Model
internal final class TodoItem {
    /// Human-readable task title.
    internal var title: String

    /// Whether the task has been completed.
    internal var isCompleted: Bool

    /// Wall-clock creation date.
    internal var createdAt: Date

    /// Creates a new `TodoItem`.
    /// - Parameters:
    ///   - title: Human-readable task title.
    ///   - isCompleted: Completion state; defaults to `false`.
    ///   - createdAt: Creation timestamp; defaults to now.
    internal init(
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}
#endif
