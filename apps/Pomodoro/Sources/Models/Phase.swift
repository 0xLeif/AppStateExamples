import SwiftUI

// MARK: - Phase

/// The current phase of a Pomodoro cycle.
///
/// Driving the ring color, phase label, and duration lookup — all from one source of truth.
internal enum Phase: String, Sendable, CaseIterable {

    // MARK: Cases

    /// An active focus/work interval.
    case work = "Focus"

    /// A short rest between work intervals.
    case shortBreak = "Short Break"

    /// A longer rest after a full set of work intervals.
    case longBreak = "Long Break"

    // MARK: Properties

    /// A human-readable label displayed in the UI.
    internal var label: String { rawValue }

    /// The accent color used for the progress ring and phase badge.
    internal var color: Color {
        switch self {
        case .work: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }

    /// The SF Symbol name that represents this phase.
    internal var symbolName: String {
        switch self {
        case .work: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer"
        case .longBreak: return "bed.double"
        }
    }

    /// Produces the next phase given a completed-sessions count.
    ///
    /// Every 4 completed work sessions triggers a long break; otherwise a short break.
    /// - Parameter completedSessions: Total work sessions completed so far.
    /// - Returns: The phase that should follow this one.
    internal func next(completedSessions: Int) -> Phase {
        switch self {
        case .work:
            return completedSessions % 4 == 0 ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }
}
