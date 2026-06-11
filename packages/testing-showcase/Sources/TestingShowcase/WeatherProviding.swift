import Foundation

// MARK: - WeatherProviding

/// Fetches weather data for a given city.
///
/// Injecting this protocol via `Application.dependency` means tests can
/// substitute a fast, deterministic mock without hitting a real network.
public protocol WeatherProviding: Sendable {
    /// Returns the current temperature (°C) for the named city.
    ///
    /// - Parameter city: The human-readable city name.
    /// - Throws: `WeatherError.unavailable` when the data cannot be fetched.
    func currentTemperature(for city: String) async throws -> Double
}

// MARK: - WeatherError

/// Errors that may be produced by a `WeatherProviding` implementation.
public enum WeatherError: Error, LocalizedError, Sendable {
    /// The provider could not retrieve data (network, parsing, or service failure).
    case unavailable(String)

    public var errorDescription: String? {
        switch self {
        case .unavailable(let reason): return "Weather unavailable: \(reason)"
        }
    }
}

// MARK: - LiveWeatherProvider

/// A "live" provider that returns a deterministic stub temperature so this
/// example compiles and runs without a real API key.
///
/// In a real app you would replace this body with an `URLSession` call.
public struct LiveWeatherProvider: WeatherProviding {
    /// Creates a new `LiveWeatherProvider`.
    public init() {}

    /// Returns a hardcoded temperature (20.0 °C) for every city.
    ///
    /// The value is intentionally fixed so the showcase can run offline and
    /// the live provider is still distinguishable from mock overrides.
    public func currentTemperature(for city: String) async throws -> Double {
        // Stub: a real implementation would perform an async network request here.
        return 20.0
    }
}
