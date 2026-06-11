import Foundation

// MARK: - UserSettings

/// A composite settings value used to demonstrate `@Slice` — editing
/// one field without touching the rest of the struct.
internal struct UserSettings: Codable, Sendable, Equatable {
    /// The user's preferred font size.
    internal var fontSize: Double

    /// Whether notifications are enabled.
    internal var notificationsEnabled: Bool

    /// A personal motto shown in the UI.
    internal var motto: String

    /// Creates a `UserSettings` with sensible defaults.
    internal init(
        fontSize: Double = 14,
        notificationsEnabled: Bool = true,
        motto: String = ""
    ) {
        self.fontSize = fontSize
        self.notificationsEnabled = notificationsEnabled
        self.motto = motto
    }
}
