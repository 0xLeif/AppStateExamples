import AppState
import Foundation

// MARK: - PomodoroEngine

/// The single controller that owns all Pomodoro state mutations.
///
/// `PomodoroEngine` is the only place that reads and writes `Application`'s
/// Pomodoro state. Views observe state via `@AppState`; they call engine
/// methods rather than mutating state directly.
///
/// Keeping mutations centralised here makes the flow easy to follow:
///   1. View calls `start()` / `pause()` / `reset()`
///   2. Engine mutates `Application` state
///   3. SwiftUI re-renders automatically via `@Observable`
@MainActor
internal final class PomodoroEngine {

    // MARK: Singleton

    /// The shared engine instance used throughout the app.
    internal static let shared = PomodoroEngine()

    // MARK: Private State

    /// Holds the live ticker token while the timer is running.
    private var tickerToken: TickerToken?

    // MARK: Lifecycle

    private init() {}

    // MARK: Public Controls

    /// Starts (or resumes) the countdown timer.
    internal func start() {
        guard tickerToken == nil else { return }

        var running = Application.state(\.isRunning)
        running.value = true

        let ticker = Application.dependency(\.ticker)
        tickerToken = ticker.start(onTick: { [weak self] in
            await self?.tick()
        })
    }

    /// Pauses the countdown, preserving the remaining time.
    internal func pause() {
        tickerToken?.cancel()
        tickerToken = nil

        var running = Application.state(\.isRunning)
        running.value = false
    }

    /// Resets the timer to the start of the current phase without changing phase or session count.
    internal func reset() {
        pause()

        let seconds = secondsForCurrentPhase()
        var remaining = Application.state(\.remainingSeconds)
        remaining.value = seconds
    }

    // MARK: Internal Mechanics

    /// Decrements remaining time by one second, advancing the phase when it reaches zero.
    internal func tick() {
        var remaining = Application.state(\.remainingSeconds)
        let current = remaining.value

        if current > 1 {
            remaining.value = current - 1
        } else {
            remaining.value = 0
            advancePhase()
        }
    }

    /// Advances to the next phase, bumping `completedSessions` when a work interval ends.
    internal func advancePhase() {
        pause()

        let currentPhase = Application.state(\.phase).value
        var sessions = Application.state(\.completedSessions)

        if currentPhase == .work {
            sessions.value += 1
        }

        let nextPhase = currentPhase.next(completedSessions: sessions.value)

        var phase = Application.state(\.phase)
        phase.value = nextPhase

        var remaining = Application.state(\.remainingSeconds)
        remaining.value = seconds(for: nextPhase)
    }

    // MARK: Private Helpers

    /// Returns the configured second count for the current phase.
    private func secondsForCurrentPhase() -> Int {
        let phase = Application.state(\.phase).value
        return seconds(for: phase)
    }

    /// Converts persisted minute settings into a second count for the given phase.
    private func seconds(for phase: Phase) -> Int {
        switch phase {
        case .work:
            return Application.state(\.workMinutes).value * 60
        case .shortBreak:
            return Application.state(\.breakMinutes).value * 60
        case .longBreak:
            return Application.state(\.breakMinutes).value * 60 * 3
        }
    }
}
