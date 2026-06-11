import Foundation

// MARK: - GreetingProviding

/// Composes a display greeting from a stored greeting string.
internal protocol GreetingProviding: Sendable {

    /// Returns a composed greeting based on `rawGreeting`.
    /// - Parameter rawGreeting: The user-editable greeting stored in `StoredState`.
    /// - Returns: A formatted string suitable for display.
    func compose(from rawGreeting: String) -> String
}

// MARK: - LiveGreetingService

/// Live implementation that echoes the greeting with a decorative prefix.
internal struct LiveGreetingService: GreetingProviding {

    /// Creates a new `LiveGreetingService`.
    internal init() {}

    internal func compose(from rawGreeting: String) -> String {
        rawGreeting.isEmpty ? "Hello, AppState!" : "✦ \(rawGreeting)"
    }
}

// MARK: - MockGreetingService

/// Replacement used to demonstrate `Application.override` hot-swapping in production UI.
internal struct MockGreetingService: GreetingProviding {

    /// Creates a new `MockGreetingService`.
    internal init() {}

    internal func compose(from rawGreeting: String) -> String {
        "[MOCK] \(rawGreeting.isEmpty ? "No greeting set" : rawGreeting)"
    }
}
