import AppState
import Foundation

// MARK: - WeatherServiceError

/// Errors surfaced by `WeatherService`.
public enum WeatherServiceError: Error, LocalizedError, Sendable {
    /// The underlying `WeatherProviding` dependency threw an error.
    case providerFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .providerFailed(let error):
            return "Weather provider failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - WeatherService

/// Coordinates fetching weather data and writing results into `Application` state.
///
/// `WeatherService` is intentionally **stateless** — all persistence lives in
/// `Application` state so any number of callers can observe the results.
/// The service reads its dependencies (`weatherProvider`, `clock`) through
/// `Application.dependency`, making both trivially replaceable in tests.
///
/// ## Testing
/// ```swift
/// let token = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 21.0))
/// try await WeatherService.refresh(city: "Paris")
/// XCTAssertEqual(Application.state(\.lastTemperature).value, 21.0)
/// await token.cancel()
/// ```
@MainActor
public enum WeatherService {

    // MARK: - Public Interface

    /// Fetches the current temperature for `city` and updates shared `Application` state.
    ///
    /// On success:
    /// - `Application.lastTemperature` is set to the returned temperature.
    /// - `Application.lastCity` is set to `city`.
    /// - `Application.lastRefreshTimestamp` is set to `clock.now()`.
    /// - `Application.refreshCount` is incremented by one.
    ///
    /// On failure the state is **not** modified and a `WeatherServiceError` is thrown,
    /// allowing callers to distinguish a failed refresh from a successful one by
    /// checking whether `refreshCount` changed.
    ///
    /// - Parameter city: The city name to look up.
    /// - Throws: `WeatherServiceError.providerFailed` wrapping the provider's error.
    public static func refresh(city: String) async throws {
        let provider = Application.dependency(\.weatherProvider)
        let clock = Application.dependency(\.clock)

        let temperature: Double
        do {
            temperature = try await provider.currentTemperature(for: city)
        } catch {
            throw WeatherServiceError.providerFailed(underlying: error)
        }

        // All mutations must happen on the main thread; @MainActor isolation ensures this.
        var tempState = Application.state(\.lastTemperature)
        tempState.value = temperature

        var cityState = Application.storedState(\.lastCity)
        cityState.value = city

        var timestampState = Application.state(\.lastRefreshTimestamp)
        timestampState.value = clock.now()

        var countState = Application.state(\.refreshCount)
        countState.value = countState.value + 1
    }
}
