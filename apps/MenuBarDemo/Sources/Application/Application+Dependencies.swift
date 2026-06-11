import AppState

// MARK: - Application Dependency Extensions

extension Application {

    // MARK: Services

    /// The injected greeting composer. Swap at runtime via `Application.override(\.greetingService, with:)`.
    internal var greetingService: Dependency<any GreetingProviding> {
        dependency(LiveGreetingService(), id: "menuBarGreetingService")
    }
}
