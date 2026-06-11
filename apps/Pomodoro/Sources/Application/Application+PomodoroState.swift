import AppState

// MARK: - Application Pomodoro State

extension Application {

    // MARK: Live Timer State (in-memory, resets on launch)

    /// The current Pomodoro phase — work, short break, or long break.
    internal var phase: State<Phase> {
        state(initial: .work, id: "pomodoro.phase")
    }

    /// Seconds remaining in the active interval.
    internal var remainingSeconds: State<Int> {
        state(initial: 25 * 60, id: "pomodoro.remainingSeconds")
    }

    /// Whether the countdown is actively running.
    internal var isRunning: State<Bool> {
        state(initial: false, id: "pomodoro.isRunning")
    }

    // MARK: Persisted Settings (UserDefaults-backed)

    /// Length of a focus/work interval in minutes. Defaults to 25.
    internal var workMinutes: StoredState<Int> {
        storedState(initial: 25, id: "pomodoro.workMinutes")
    }

    /// Length of a short break in minutes. Defaults to 5.
    internal var breakMinutes: StoredState<Int> {
        storedState(initial: 5, id: "pomodoro.breakMinutes")
    }

    /// Cumulative count of completed focus sessions. Persisted so it survives launches.
    internal var completedSessions: StoredState<Int> {
        storedState(initial: 0, id: "pomodoro.completedSessions")
    }
}
