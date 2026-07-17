import SwiftUI
import XCTest
import AppState
import SnapshotTesting
@testable import Pomodoro

// MARK: - Pomodoro Snapshot Tests

/// Image regression coverage for every timer phase and the settings surface.
@MainActor
internal final class PomodoroSnapshotTests: XCTestCase {
    internal func testFocusTimerInitialState() {
        seed(phase: .work, remainingSeconds: 25 * 60, isRunning: false, completedSessions: 0)
        assertScreenSnapshot(of: TimerScreenView(), named: "focus-initial")
    }

    internal func testRunningFocusTimer() {
        seed(phase: .work, remainingSeconds: 12 * 60 + 34, isRunning: true, completedSessions: 1)
        assertScreenSnapshot(of: TimerScreenView(), named: "focus-running")
    }

    internal func testShortBreakTimer() {
        seed(phase: .shortBreak, remainingSeconds: 4 * 60 + 15, isRunning: false, completedSessions: 2)
        assertScreenSnapshot(of: TimerScreenView(), named: "short-break")
    }

    internal func testLongBreakTimer() {
        seed(phase: .longBreak, remainingSeconds: 14 * 60, isRunning: false, completedSessions: 4)
        assertScreenSnapshot(of: TimerScreenView(), named: "long-break")
    }

    internal func testSettingsWithCompletedSessions() {
        var workMinutes = Application.storedState(\.workMinutes)
        workMinutes.value = 30
        var breakMinutes = Application.storedState(\.breakMinutes)
        breakMinutes.value = 7
        var sessions = Application.storedState(\.completedSessions)
        sessions.value = 4

        assertScreenSnapshot(of: SettingsView(), named: "settings")
    }

    internal func testFormattingAndBadgeVariants() {
        let view = VStack(spacing: 24) {
            TimerDisplayView(remainingSeconds: 65, color: .red)
            SessionBadgeView(completedSessions: 0)
            SessionBadgeView(completedSessions: 1)
            SessionBadgeView(completedSessions: 5)
            TimerRingView(progress: 0.5, color: .blue, diameter: 160)
        }
        .padding()

        assertSnapshot(
            of: view,
            as: .image(
                layout: .fixed(width: 390, height: 600),
                traits: UITraitCollection(userInterfaceStyle: .light)
            ),
            named: "components",
            record: .missing
        )
    }

    private func seed(
        phase: Phase,
        remainingSeconds: Int,
        isRunning: Bool,
        completedSessions: Int
    ) {
        var phaseState = Application.state(\.phase)
        phaseState.value = phase
        var remainingState = Application.state(\.remainingSeconds)
        remainingState.value = remainingSeconds
        var runningState = Application.state(\.isRunning)
        runningState.value = isRunning
        var workMinutes = Application.storedState(\.workMinutes)
        workMinutes.value = 25
        var breakMinutes = Application.storedState(\.breakMinutes)
        breakMinutes.value = 5
        var sessions = Application.storedState(\.completedSessions)
        sessions.value = completedSessions
    }

    private func assertScreenSnapshot<Content: View>(of view: Content, named name: String) {
        assertSnapshot(
            of: view,
            as: .image(
                layout: .device(config: .iPhone13),
                traits: UITraitCollection(userInterfaceStyle: .light)
            ),
            named: name,
            record: .missing
        )
    }
}
