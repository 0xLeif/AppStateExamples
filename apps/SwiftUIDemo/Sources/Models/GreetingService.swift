import Foundation

// MARK: - GreetingProviding

/// Produces a greeting string for a given name.
internal protocol GreetingProviding: Sendable {
    /// Returns a greeting for `name`.
    func greet(_ name: String) -> String
}

// MARK: - LiveGreetingService

/// Live implementation that returns a friendly greeting.
internal struct LiveGreetingService: GreetingProviding {
    /// Creates a new `LiveGreetingService`.
    internal init() {}

    internal func greet(_ name: String) -> String {
        "Hello, \(name.isEmpty ? "World" : name)! 👋"
    }
}

// MARK: - MockGreetingService

/// A swapped-in implementation used to demonstrate `Application.override`.
internal struct MockGreetingService: GreetingProviding {
    /// Creates a new `MockGreetingService`.
    internal init() {}

    internal func greet(_ name: String) -> String {
        "[MOCK] Greetings, \(name.isEmpty ? "stranger" : name)!"
    }
}
