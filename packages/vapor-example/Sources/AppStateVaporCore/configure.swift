import AppState
import Foundation
import Vapor

// MARK: - configure

/// Configures the Vapor application: registers routes and starts background observers.
///
/// Call this once from the entry point before running `app.run()`.
///
/// - Parameter app: The `Vapor.Application` to configure.
public func configure(_ app: Vapor.Application) async throws {
    // Enable AppState logging in development so dependency resolution is visible.
    await MainActor.run {
        Application.logging(isEnabled: app.environment == .development)
    }

    // Pre-warm the AppState dependencies so they are ready before any request
    // arrives.  load(dependency:) is @MainActor so we hop once.
    await MainActor.run {
        Application.load(dependency: \.greetingService)
        Application.load(dependency: \.requestMetrics)
    }

    // Start the headless observation loop.  The observer watches
    // `totalRequestCount` via withObservationTracking and logs every change.
    // Because MetricsObserver is @MainActor-isolated we start it on the main
    // actor; it self-manages re-arming from that point on.
    let observer = await MainActor.run { MetricsObserver(label: "[MetricsObserver]") }
    await observer.start()

    // Register HTTP routes.
    registerRoutes(on: app)
}
