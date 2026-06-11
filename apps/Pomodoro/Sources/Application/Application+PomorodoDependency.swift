import AppState

// MARK: - Application Pomodoro Dependency

extension Application {

    /// The injected ticker service that drives one-second heartbeats.
    ///
    /// Swap this out in tests or previews via `Application.override(\.ticker, with:)`.
    internal var ticker: Dependency<any Ticker> {
        dependency(LiveTicker(), id: "pomodoro.ticker")
    }
}
