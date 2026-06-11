import Foundation

// MARK: - Profile

/// A user profile persisted to the app-sandbox file system via `@FileState`.
internal struct Profile: Codable, Sendable, Equatable {
    /// The user's display name.
    internal var displayName: String

    /// A short bio or status message.
    internal var bio: String

    /// Creates a default empty profile.
    internal init(displayName: String = "", bio: String = "") {
        self.displayName = displayName
        self.bio = bio
    }
}
