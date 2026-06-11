import AppState

// MARK: - Application Extension

extension Application {

    // MARK: - In-Memory State

    /// The temperature (°C) returned by the most recent successful refresh.
    ///
    /// Starts at `0.0`. Reset this in `setUp` to isolate tests from one another.
    public var lastTemperature: State<Double> {
        state(initial: 0.0, id: "weather.lastTemperature")
    }

    /// How many successful `WeatherService.refresh(city:)` calls have completed.
    ///
    /// Starts at `0`. Reset this in `setUp` to isolate tests from one another.
    public var refreshCount: State<Int> {
        state(initial: 0, id: "weather.refreshCount")
    }

    /// The Unix epoch timestamp (seconds) captured during the last successful refresh.
    ///
    /// Starts at `0`. Lets tests verify which `Clock` instance was active.
    public var lastRefreshTimestamp: State<Int> {
        state(initial: 0, id: "weather.lastRefreshTimestamp")
    }

    // MARK: - UserDefaults-Backed State

    /// The name of the city supplied to the most recent `refresh(city:)` call.
    ///
    /// `StoredState` persists across process launches; tests should reset it in `setUp`.
    public var lastCity: StoredState<String> {
        storedState(initial: "", id: "weather.lastCity")
    }

    // MARK: - Dependencies

    /// The active weather data provider. Swap via `Application.override` in tests.
    public var weatherProvider: Dependency<any WeatherProviding> {
        dependency(LiveWeatherProvider(), id: "weather.weatherProvider")
    }

    /// The active clock. Swap via `Application.override` in tests.
    public var clock: Dependency<any Clock> {
        dependency(SystemClock(), id: "weather.clock")
    }
}
