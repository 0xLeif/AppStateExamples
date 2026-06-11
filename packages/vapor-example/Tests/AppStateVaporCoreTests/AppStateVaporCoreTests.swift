import AppState
@testable import AppStateVaporCore
import XCTest
import XCTVapor

// MARK: - MockGreetingService

/// Deterministic `GreetingService` for test isolation.
private struct MockGreetingService: GreetingService {
    /// The fixed string returned from `greet(name:template:appName:)`.
    let response: String

    func greet(name: String, template: String, appName: String) -> String {
        response
    }
}

// MARK: - AppStateVaporCoreTests

final class AppStateVaporCoreTests: XCTestCase {

    // MARK: - Helpers

    /// Boots a test `Vapor.Application`, runs `configure`, and tears it down after the closure.
    ///
    /// Uses `Application.make(.testing)` (the async API required in Vapor 4.92+) and
    /// `app.asyncShutdown()` to avoid blocking the EventLoop thread.
    private func withApp(_ block: (Vapor.Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await block(app)
            try await app.asyncShutdown()
        } catch {
            try? await app.asyncShutdown()
            throw error
        }
    }

    /// Helper that calls `app.testable()` and runs the async `test` method.
    ///
    /// In Vapor 4.92+ the `test` method on `Application` is unavailable in async contexts.
    /// Use `app.testable().test(...)` instead.
    private func testRequest(
        on app: Vapor.Application,
        _ method: HTTPMethod,
        _ path: String,
        afterResponse: @Sendable (XCTHTTPResponse) async throws -> Void
    ) async throws {
        let tester = try app.testable()
        try await tester.test(method, path, afterResponse: afterResponse)
    }

    private func testRequest(
        on app: Vapor.Application,
        _ method: HTTPMethod,
        _ path: String,
        beforeRequest: @Sendable (inout XCTHTTPRequest) async throws -> Void,
        afterResponse: @Sendable (XCTHTTPResponse) async throws -> Void
    ) async throws {
        let tester = try app.testable()
        try await tester.test(
            method,
            path,
            beforeRequest: beforeRequest,
            afterResponse: afterResponse
        )
    }

    /// Resets the AppState counters that tests modify so they don't leak between cases.
    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            // Bind to `var` so the compiler accepts `.value = …` mutation.
            // The setter writes to Application.shared.cache, making the change durable.
            var countState = Application.state(\.totalRequestCount)
            countState.value = 0
            var nameState = Application.state(\.appName)
            nameState.value = "AppState Vapor Example"
            var templateState = Application.storedState(\.greetingTemplate)
            templateState.value = "Hello, {name}! Welcome to {appName}."
        }
        let metrics = await MainActor.run { Application.dependency(\.requestMetrics) }
        await metrics.reset()
    }

    // MARK: - Test 1: Health Endpoint

    /// `GET /` returns HTTP 200 with a JSON body containing `"status": "ok"`.
    func testHealthEndpointReturnsOK() async throws {
        try await withApp { app in
            try await self.testRequest(on: app, .GET, "/") { response in
                XCTAssertEqual(response.status, .ok)

                let body = try response.content.decode(HealthResponse.self)
                XCTAssertEqual(body.status, "ok")
                XCTAssertFalse(body.appName.isEmpty)
            }
        }
    }

    // MARK: - Test 2: Health Endpoint Returns AppName State

    /// `GET /` reflects the current `appName` State value.
    func testHealthEndpointReflectsAppNameState() async throws {
        await MainActor.run {
            var nameState = Application.state(\.appName)
            nameState.value = "TestServer"
        }

        try await withApp { app in
            try await self.testRequest(on: app, .GET, "/") { response in
                let body = try response.content.decode(HealthResponse.self)
                XCTAssertEqual(body.appName, "TestServer")
            }
        }
    }

    // MARK: - Test 3: Greet Endpoint Uses Injected Service

    /// `GET /greet/:name` calls the injected `GreetingService`.
    ///
    /// We override `greetingService` with a `MockGreetingService` and verify
    /// the handler returns the mock's fixed response — proving the dependency
    /// injection path works end-to-end.
    func testGreetEndpointUsesInjectedService() async throws {
        let override = await MainActor.run {
            Application.override(
                \.greetingService,
                with: MockGreetingService(response: "Mocked greeting!") as any GreetingService
            )
        }
        defer { Task { await override.cancel() } }

        try await withApp { app in
            try await self.testRequest(on: app, .GET, "/greet/Alice") { response in
                XCTAssertEqual(response.status, .ok)

                let body = try response.content.decode(GreetResponse.self)
                XCTAssertEqual(body.greeting, "Mocked greeting!")
            }
        }
    }

    // MARK: - Test 4: Greet Endpoint With Live Service

    /// `GET /greet/:name` with the live service applies the greeting template correctly.
    func testGreetEndpointWithLiveService() async throws {
        await MainActor.run {
            var templateState = Application.storedState(\.greetingTemplate)
            templateState.value = "Hi {name}, from {appName}!"
            var nameState = Application.state(\.appName)
            nameState.value = "VaporDemo"
        }

        try await withApp { app in
            try await self.testRequest(on: app, .GET, "/greet/Bob") { response in
                XCTAssertEqual(response.status, .ok)

                let body = try response.content.decode(GreetResponse.self)
                XCTAssertEqual(body.greeting, "Hi Bob, from VaporDemo!")
            }
        }
    }

    // MARK: - Test 5: Metrics Endpoint

    /// `GET /metrics` returns a valid `MetricsResponse` with integer counts.
    func testMetricsEndpointReturnsValidSnapshot() async throws {
        try await withApp { app in
            // Seed some traffic first.
            try await self.testRequest(on: app, .GET, "/") { _ in }
            try await self.testRequest(on: app, .GET, "/greet/Carol") { _ in }

            try await self.testRequest(on: app, .GET, "/metrics") { response in
                XCTAssertEqual(response.status, .ok)

                let body = try response.content.decode(MetricsResponse.self)
                // After seeding two requests, totalRequests must be at least 2.
                XCTAssertGreaterThanOrEqual(body.totalRequests, 2)
                XCTAssertFalse(body.routeCounts.isEmpty)
            }
        }
    }

    // MARK: - Test 6: Config Endpoint Mutates AppName State

    /// `POST /config` with `{"appName":"NewName"}` updates the `appName` State
    /// and returns the new value — demonstrating the main-thread mutation pattern.
    func testConfigEndpointMutatesAppNameState() async throws {
        try await withApp { app in
            let payload = ConfigUpdateRequest(appName: "UpdatedName", greetingTemplate: nil)

            try await self.testRequest(
                on: app,
                .POST,
                "/config",
                beforeRequest: { req in
                    try req.content.encode(payload, as: .json)
                },
                afterResponse: { response in
                    XCTAssertEqual(response.status, .ok)

                    let body = try response.content.decode(ConfigUpdateResponse.self)
                    XCTAssertEqual(body.appName, "UpdatedName")
                }
            )
        }
    }

    // MARK: - Test 7: Config Endpoint Updates Greeting Template

    /// `POST /config` with a new template is reflected immediately on `GET /greet/:name`.
    func testConfigEndpointUpdatesGreetingTemplate() async throws {
        try await withApp { app in
            let configPayload = ConfigUpdateRequest(
                appName: nil,
                greetingTemplate: "Greetings, {name}!"
            )

            try await self.testRequest(
                on: app,
                .POST,
                "/config",
                beforeRequest: { req in
                    try req.content.encode(configPayload, as: .json)
                },
                afterResponse: { response in
                    XCTAssertEqual(response.status, .ok)
                }
            )

            try await self.testRequest(on: app, .GET, "/greet/Dana") { response in
                let body = try response.content.decode(GreetResponse.self)
                XCTAssertEqual(body.greeting, "Greetings, Dana!")
            }
        }
    }

    // MARK: - Test 8: RequestMetrics Actor Thread Safety

    /// Concurrently recording many routes should not crash or produce negative counts.
    func testRequestMetricsActorHandlesConcurrentWrites() async throws {
        let metrics = await MainActor.run { Application.dependency(\.requestMetrics) }

        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< 100 {
                group.addTask {
                    await metrics.record(route: index.isMultiple(of: 2) ? "GET /" : "GET /greet/:name")
                }
            }
        }

        let evenCount = await metrics.count(for: "GET /")
        let oddCount = await metrics.count(for: "GET /greet/:name")
        XCTAssertEqual(evenCount + oddCount, 100)
        XCTAssertGreaterThan(evenCount, 0)
        XCTAssertGreaterThan(oddCount, 0)
    }
}
