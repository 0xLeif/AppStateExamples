import AppState

// MARK: - Application Dependency Extensions

extension Application {

    // MARK: Services

    /// The injected greeting service. Swap via `Application.override(\.greetingService, with:)`.
    internal var greetingService: Dependency<any GreetingProviding> {
        dependency(LiveGreetingService(), id: "greetingService")
    }

    /// An `Observable` counter service, observed via `@ObservedDependency`.
    internal var counterService: Dependency<LiveCounterService> {
        dependency(LiveCounterService(), id: "counterService")
    }
}
