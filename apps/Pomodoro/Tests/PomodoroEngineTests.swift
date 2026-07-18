import XCTest
import AppState
@testable import Pomodoro

// MARK: - Pomodoro Engine Tests

/// Branch coverage for phase transitions and all timer controls.
@MainActor
internal final class PomodoroEngineTests: XCTestCase {
    internal override func setUp() async throws {
        PomodoroEngine.shared.pause()

        var phase = Application.state(\.phase)
        phase.value = .work
        var remaining = Application.state(\.remainingSeconds)
        remaining.value = 25 * 60
        var running = Application.state(\.isRunning)
        running.value = false
        var workMinutes = Application.storedState(\.workMinutes)
        workMinutes.value = 25
        var breakMinutes = Application.storedState(\.breakMinutes)
        breakMinutes.value = 5
        var completedSessions = Application.storedState(\.completedSessions)
        completedSessions.value = 0
    }

    internal override func tearDown() async throws {
        PomodoroEngine.shared.pause()
    }

    internal func testPhaseMetadataAndTransitions() {
        XCTAssertEqual(Phase.allCases.map(\.label), ["Focus", "Short Break", "Long Break"])
        XCTAssertEqual(Phase.work.symbolName, "brain.head.profile")
        XCTAssertEqual(Phase.shortBreak.symbolName, "cup.and.saucer")
        XCTAssertEqual(Phase.longBreak.symbolName, "bed.double")
        XCTAssertEqual(Phase.work.next(completedSessions: 1), .shortBreak)
        XCTAssertEqual(Phase.work.next(completedSessions: 4), .longBreak)
        XCTAssertEqual(Phase.shortBreak.next(completedSessions: 1), .work)
        XCTAssertEqual(Phase.longBreak.next(completedSessions: 4), .work)
    }

    internal func testStartIsIdempotentAndPauseStopsTimer() {
        PomodoroEngine.shared.start()
        XCTAssertTrue(Application.state(\.isRunning).value)

        PomodoroEngine.shared.start()
        XCTAssertTrue(Application.state(\.isRunning).value)

        PomodoroEngine.shared.pause()
        XCTAssertFalse(Application.state(\.isRunning).value)
    }

    internal func testTickDecrementsPositiveRemainingTime() {
        var remaining = Application.state(\.remainingSeconds)
        remaining.value = 12

        PomodoroEngine.shared.tick()

        XCTAssertEqual(Application.state(\.remainingSeconds).value, 11)
        XCTAssertEqual(Application.state(\.phase).value, .work)
        XCTAssertEqual(Application.storedState(\.completedSessions).value, 0)
    }

    internal func testWorkCompletionAdvancesToShortBreak() {
        var remaining = Application.state(\.remainingSeconds)
        remaining.value = 1

        PomodoroEngine.shared.tick()

        XCTAssertEqual(Application.state(\.phase).value, .shortBreak)
        XCTAssertEqual(Application.state(\.remainingSeconds).value, 5 * 60)
        XCTAssertEqual(Application.storedState(\.completedSessions).value, 1)
        XCTAssertFalse(Application.state(\.isRunning).value)
    }

    internal func testFourthWorkCompletionAdvancesToLongBreak() {
        var sessions = Application.storedState(\.completedSessions)
        sessions.value = 3

        PomodoroEngine.shared.advancePhase()

        XCTAssertEqual(Application.state(\.phase).value, .longBreak)
        XCTAssertEqual(Application.state(\.remainingSeconds).value, 15 * 60)
        XCTAssertEqual(Application.storedState(\.completedSessions).value, 4)
    }

    internal func testBreakCompletionReturnsToWorkWithoutIncrementingSessions() {
        var phase = Application.state(\.phase)
        phase.value = .longBreak
        var sessions = Application.storedState(\.completedSessions)
        sessions.value = 4

        PomodoroEngine.shared.advancePhase()

        XCTAssertEqual(Application.state(\.phase).value, .work)
        XCTAssertEqual(Application.state(\.remainingSeconds).value, 25 * 60)
        XCTAssertEqual(Application.storedState(\.completedSessions).value, 4)
    }

    internal func testResetUsesConfiguredDurationForEveryPhase() {
        var workMinutes = Application.storedState(\.workMinutes)
        workMinutes.value = 2
        var breakMinutes = Application.storedState(\.breakMinutes)
        breakMinutes.value = 3
        var phase = Application.state(\.phase)

        phase.value = .work
        PomodoroEngine.shared.reset()
        XCTAssertEqual(Application.state(\.remainingSeconds).value, 120)

        phase.value = .shortBreak
        PomodoroEngine.shared.reset()
        XCTAssertEqual(Application.state(\.remainingSeconds).value, 180)

        phase.value = .longBreak
        PomodoroEngine.shared.reset()
        XCTAssertEqual(Application.state(\.remainingSeconds).value, 540)
    }
}
