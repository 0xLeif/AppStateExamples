import AppState
import Foundation

// MARK: - Application Extension

extension Application {

    // MARK: Scalar In-Memory State

    /// The current counter value. Incremented/decremented by the user.
    public var counter: State<Int> {
        state(initial: 0, id: "tui.counter")
    }

    /// The current temperature reading in degrees Celsius.
    public var temperature: State<Double> {
        state(initial: 20.0, id: "tui.temperature")
    }

    /// Whether the dashboard auto-refresh is paused.
    public var paused: State<Bool> {
        state(initial: false, id: "tui.paused")
    }

    // MARK: Persisted State (UserDefaults)

    /// A user-defined label shown in the dashboard header. Persists across sessions.
    public var dashboardLabel: StoredState<String> {
        storedState(initial: "AppState Live Dashboard", id: "tui.dashboardLabel")
    }

    // MARK: Dependencies

    /// The injected frame-styling dependency. Override in tests or alternate themes.
    public var frameStyling: Dependency<any FrameStyling> {
        dependency(DefaultFrameStyling(), id: "tui.frameStyling")
    }
}
