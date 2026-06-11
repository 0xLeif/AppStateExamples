import AppState
import Foundation

// MARK: - Application + VaporState

/// Centralises every piece of AppState used by the Vapor example.
///
/// All state and dependency registrations live here so that route handlers
/// and tests share a single, consistent namespace.
public extension Application {

    // MARK: - Config State

    /// The human-readable name of the running application instance.
    ///
    /// Backed by `State<String>` so it lives in-process only.
    /// Mutate via `await MainActor.run { Application.state(\.appName).value = … }`.
    var appName: State<String> {
        state(initial: "AppState Vapor Example", id: "appName")
    }

    /// The template used to construct greeting responses.
    ///
    /// Placeholders: `{appName}` and `{name}`.
    /// Backed by `StoredState` so it persists across restarts via `UserDefaults`.
    var greetingTemplate: StoredState<String> {
        storedState(initial: "Hello, {name}! Welcome to {appName}.", id: "greetingTemplate")
    }

    // MARK: - Metrics State

    /// Running total of HTTP requests handled since boot.
    ///
    /// Incremented on the main thread so `withObservationTracking` picks up
    /// every change — see `MetricsObserver` for the observation loop.
    var totalRequestCount: State<Int> {
        state(initial: 0, id: "totalRequestCount")
    }

    /// Per-route hit counters keyed by `"METHOD /path"`.
    var routeHits: State<[String: Int]> {
        state(initial: [:], id: "routeHits")
    }

    // MARK: - Dependencies

    /// The active `GreetingService` implementation.
    ///
    /// Override in tests: `Application.override(\.greetingService, with: MockGreetingService())`.
    var greetingService: Dependency<any GreetingService> {
        dependency(LiveGreetingService() as any GreetingService, id: "greetingService")
    }

    /// Shared in-memory request-metrics actor.
    ///
    /// The actor is safe to call from any concurrency context — no main-thread
    /// hop required. Used for detailed per-endpoint counters beyond the simple
    /// `State<Int>` counter above.
    var requestMetrics: Dependency<RequestMetrics> {
        dependency(RequestMetrics(), id: "requestMetrics")
    }
}
