import AppStateVaporCore
import Vapor

// MARK: - Entry Point

/// Application entry point.
///
/// Vapor's `Application` is configured via the shared `configure(_:)` function
/// which lives in `AppStateVaporCore` (the testable library target).
/// Keeping configuration in the library and the entry point thin lets
/// `XCTVapor` boot the same `configure(_:)` path in tests without duplicating logic.
@main
internal struct VaporExampleEntryPoint {
    internal static func main() async throws {
        // Build a Vapor Application in the default environment (.development
        // when no $APP_ENV is set, or override via the environment variable).
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        // Vapor 4.92+ requires Application.make(_:) in async contexts.
        // The sync Application(_:) initializer is unavailable in async scope.
        let app = try await Application.make(env)
        do {
            try await configure(app)
            try await app.execute()
            try await app.asyncShutdown()
        } catch {
            try? await app.asyncShutdown()
            throw error
        }
    }
}
