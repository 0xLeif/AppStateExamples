import Foundation

// MARK: - GreetingService

/// Produces a personalised greeting string given a name and a template.
///
/// Protocol-based so tests can inject a `MockGreetingService` via
/// `Application.override(\.greetingService, with: …)` without touching
/// production code.
public protocol GreetingService: Sendable {
    /// Formats a greeting using the provided template and recipient name.
    ///
    /// - Parameters:
    ///   - name: The name to address in the greeting.
    ///   - template: Template string; `{name}` and `{appName}` are replaced.
    ///   - appName: The application name substituted for `{appName}`.
    /// - Returns: A fully resolved greeting string.
    func greet(name: String, template: String, appName: String) -> String
}

// MARK: - LiveGreetingService

/// Production `GreetingService` that performs simple token replacement.
public struct LiveGreetingService: GreetingService {
    /// Creates a new `LiveGreetingService`.
    public init() {}

    public func greet(name: String, template: String, appName: String) -> String {
        template
            .replacingOccurrences(of: "{name}", with: name)
            .replacingOccurrences(of: "{appName}", with: appName)
    }
}
