// MARK: - DashboardCommand

/// All actions the user can dispatch to the live dashboard.
///
/// Each case maps to a key in the interactive terminal loop:
///
/// | Key | Command       |
/// |-----|---------------|
/// | `i` | increment     |
/// | `d` | decrement     |
/// | `w` | warmer        |
/// | `c` | cooler        |
/// | `p` | togglePause   |
/// | `r` | reset         |
/// | `q` | quit          |
public enum DashboardCommand: String, CaseIterable, Sendable {
    case increment
    case decrement
    case warmer
    case cooler
    case togglePause
    case reset
    case quit

    // MARK: Key Mapping

    /// Returns the `DashboardCommand` corresponding to the given single-character key, or `nil`
    /// if the key is unrecognised.
    ///
    /// - Parameter key: A single `Character` typed by the user.
    public static func from(key: Character) -> DashboardCommand? {
        switch key {
        case "i": return .increment
        case "d": return .decrement
        case "w": return .warmer
        case "c": return .cooler
        case "p": return .togglePause
        case "r": return .reset
        case "q": return .quit
        default: return nil
        }
    }

    /// A human-readable label for display in the help footer.
    public var label: String {
        switch self {
        case .increment: return "[i] +1 counter"
        case .decrement: return "[d] -1 counter"
        case .warmer: return "[w] +5° temp"
        case .cooler: return "[c] -5° temp"
        case .togglePause: return "[p] pause/resume"
        case .reset: return "[r] reset all"
        case .quit: return "[q] quit"
        }
    }
}
