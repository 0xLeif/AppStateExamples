// MARK: - Formatting

/// Converts a raw counter value into a human-readable display string.
///
/// Keeping the formatting logic in `WASMCore` (away from JavaScriptKit) means
/// it can be unit-tested on the host without a wasm SDK.
public protocol CounterFormatting: Sendable {
    /// Returns the display label for the given count.
    func label(for count: Int) -> String
}

// MARK: - DefaultCounterFormatter

/// Standard formatter: shows the numeric value with a descriptive suffix.
public struct DefaultCounterFormatter: CounterFormatting {
    /// Creates a `DefaultCounterFormatter`.
    public init() {}

    public func label(for count: Int) -> String {
        switch count {
        case 0:
            return "Zero"
        case 1:
            return "1 click"
        case let n where n < 0:
            return "\(n) (below zero!)"
        default:
            return "\(count) clicks"
        }
    }
}
