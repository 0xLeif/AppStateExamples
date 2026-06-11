import AppState
import Foundation
import Vapor

// MARK: - Response Models

/// Response body for `GET /`.
public struct HealthResponse: Content {
    /// Fixed status string.
    public let status: String
    /// Application name read from `Application.state(\.appName)`.
    public let appName: String
    /// Total requests served (read from the `State<Int>` counter).
    public let totalRequests: Int
}

/// Response body for `GET /greet/:name`.
public struct GreetResponse: Content {
    /// The formatted greeting produced by the injected `GreetingService`.
    public let greeting: String
}

/// Response body for `GET /metrics`.
public struct MetricsResponse: Content {
    /// Snapshot of per-route hit counts from the `RequestMetrics` actor.
    public let routeCounts: [String: Int]
    /// Total requests from the main-thread `State<Int>` counter.
    public let totalRequests: Int
}

/// Request body for `POST /config`.
public struct ConfigUpdateRequest: Content {
    /// New application name.  Optional — omit to leave unchanged.
    public let appName: String?
    /// New greeting template.  Optional — omit to leave unchanged.
    public let greetingTemplate: String?
}

/// Response body for `POST /config`.
public struct ConfigUpdateResponse: Content {
    public let appName: String
    public let greetingTemplate: String
}

// MARK: - Route Registration

/// Registers all example routes on the provided Vapor `Application`.
///
/// - Parameter app: The `Vapor.Application` instance to attach routes to.
public func registerRoutes(on app: Vapor.Application) {
    app.get("", use: healthHandler)
    app.get("greet", ":name", use: greetHandler)
    app.get("metrics", use: metricsHandler)
    app.post("config", use: configHandler)
}

// MARK: - Handlers

/// `GET /` — returns the application name and total request count.
///
/// ### Threading pattern
///
/// `Application.dependency(_:)` and `Application.state(_:)` are both `@MainActor`.
/// Vapor route handlers run on NIO EventLoop threads, so EVERY AppState access
/// (whether reading or writing) must be wrapped in `await MainActor.run { }`.
///
/// For actor-based dependencies like `RequestMetrics`, resolving the dependency
/// itself requires the main thread, but once you have a reference to the actor
/// you can call methods on it from any thread.
private func healthHandler(request: Request) async throws -> HealthResponse {
    // Record this hit in the actor-based metrics.
    // Resolving the dependency requires the main thread; calling the actor method
    // does not — so we resolve on main then call the actor method outside.
    let metrics = await MainActor.run { Application.dependency(\.requestMetrics) }
    await metrics.record(route: "GET /")

    // Read AppState values and increment counter — all on main thread.
    // IMPORTANT: Application.notifyChange() asserts Thread.isMainThread.
    // Vapor route handlers run on EventLoop threads, so we MUST hop to
    // MainActor before touching any AppState State or Dependency value.
    //
    // Note: `Application.state(_:)` returns a value-type `State<T>` copy.
    // Assign to `var` so the compiler accepts `.value = …` syntax — the
    // setter's side-effect writes to Application.shared.cache, so the
    // mutation is durable even though the local binding is temporary.
    let (appName, total) = await MainActor.run {
        let name = Application.state(\.appName).value
        let count = Application.state(\.totalRequestCount).value
        var counter = Application.state(\.totalRequestCount)
        counter.value += 1
        return (name, count)
    }

    return HealthResponse(status: "ok", appName: appName, totalRequests: total)
}

/// `GET /greet/:name` — uses the injected `GreetingService` to build a greeting.
///
/// The `GreetingService` dependency is resolved on the main thread (required by
/// `@MainActor Application.dependency(_:)`), but called afterwards from any context
/// since the service itself is `Sendable`.
private func greetHandler(request: Request) async throws -> GreetResponse {
    guard let name = request.parameters.get("name") else {
        throw Abort(.badRequest, reason: "Missing :name parameter")
    }

    let metrics = await MainActor.run { Application.dependency(\.requestMetrics) }
    await metrics.record(route: "GET /greet/:name")

    // Resolve all main-actor-isolated values in a single hop.
    let (service, appName, template) = await MainActor.run {
        let svc = Application.dependency(\.greetingService)
        let appName = Application.state(\.appName).value
        let tmpl = Application.storedState(\.greetingTemplate).value
        // Increment total request counter on main thread.
        var counter = Application.state(\.totalRequestCount)
        counter.value += 1
        return (svc, appName, tmpl)
    }

    let greeting = service.greet(name: name, template: template, appName: appName)
    return GreetResponse(greeting: greeting)
}

/// `GET /metrics` — returns a snapshot of both counter systems.
private func metricsHandler(request: Request) async throws -> MetricsResponse {
    let metrics = await MainActor.run { Application.dependency(\.requestMetrics) }
    await metrics.record(route: "GET /metrics")

    let snapshot = await metrics.snapshot

    let total = await MainActor.run {
        let count = Application.state(\.totalRequestCount).value
        var counter = Application.state(\.totalRequestCount)
        counter.value += 1
        return count
    }

    return MetricsResponse(routeCounts: snapshot, totalRequests: total)
}

/// `POST /config` — mutates `AppState` values from an EventLoop thread.
///
/// This route intentionally demonstrates the **main-thread mutation pattern**.
/// Every write to a `State` or `StoredState` value is wrapped in
/// `await MainActor.run { … }` because `Application.notifyChange()` asserts
/// `Thread.isMainThread`.  Skipping this hop causes a runtime assertion failure
/// in debug builds and a silent data race in release builds.
///
/// Note also that `Application.dependency(_:)` is `@MainActor`, so even
/// dependency READS require a main-thread hop from a Vapor route handler.
private func configHandler(request: Request) async throws -> ConfigUpdateResponse {
    let body = try request.content.decode(ConfigUpdateRequest.self)

    let metrics = await MainActor.run { Application.dependency(\.requestMetrics) }
    await metrics.record(route: "POST /config")

    // *** MAIN-THREAD MUTATION PATTERN ***
    //
    // Vapor route handlers run on NIO EventLoop threads — NOT the main thread.
    // AppState mutations trigger Application.notifyChange(), which asserts
    // Thread.isMainThread.  Always hop to MainActor before writing State.
    //
    // State.value returns a struct copy; we bind it to `var` so Swift
    // accepts the mutation syntax (`.value = …`).  The setter's side-effect
    // writes to the global Application.shared.cache — the local `var` is
    // just to satisfy the compiler.
    let (appName, template) = await MainActor.run {
        if let newName = body.appName {
            var appNameState = Application.state(\.appName)
            appNameState.value = newName
        }
        if let newTemplate = body.greetingTemplate {
            var templateState = Application.storedState(\.greetingTemplate)
            templateState.value = newTemplate
        }
        var counter = Application.state(\.totalRequestCount)
        counter.value += 1

        return (
            Application.state(\.appName).value,
            Application.storedState(\.greetingTemplate).value
        )
    }

    return ConfigUpdateResponse(appName: appName, greetingTemplate: template)
}
