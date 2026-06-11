import AppState
import Foundation

// MARK: - DashboardController

/// Pure command handler and renderer for the live dashboard.
///
/// All mutations are `@MainActor` because AppState requires main-thread writes.
/// This type is safe to use from tests without any terminal I/O — it only reads and
/// writes `Application` state and produces plain `String` frames.
public enum DashboardController: Sendable {

    // MARK: - Constants

    /// Temperature step size (°C) for warmer/cooler commands.
    private static let temperatureStep: Double = 5.0

    /// Minimum temperature the gauge will display (°C).
    public static let minimumTemperature: Double = -20.0

    /// Maximum temperature the gauge will display (°C).
    public static let maximumTemperature: Double = 100.0

    // MARK: - Command Application

    /// Applies a `DashboardCommand` to the relevant `Application` state.
    ///
    /// Returns `true` for all commands except `.quit`, which signals the run-loop to exit.
    ///
    /// - Parameter command: The command to apply.
    /// - Returns: `false` when the caller should exit the interactive loop; `true` otherwise.
    @MainActor
    @discardableResult
    public static func apply(_ command: DashboardCommand) -> Bool {
        switch command {
        case .increment:
            var counter = Application.state(\.counter)
            counter.value += 1
            return true

        case .decrement:
            var counter = Application.state(\.counter)
            counter.value -= 1
            return true

        case .warmer:
            var temperature = Application.state(\.temperature)
            temperature.value = min(temperature.value + temperatureStep, maximumTemperature)
            return true

        case .cooler:
            var temperature = Application.state(\.temperature)
            temperature.value = max(temperature.value - temperatureStep, minimumTemperature)
            return true

        case .togglePause:
            var paused = Application.state(\.paused)
            paused.value.toggle()
            return true

        case .reset:
            var counter = Application.state(\.counter)
            counter.value = 0
            var temperature = Application.state(\.temperature)
            temperature.value = 20.0
            var paused = Application.state(\.paused)
            paused.value = false
            return true

        case .quit:
            return false
        }
    }

    // MARK: - Rendering

    /// Renders the current application state as an ASCII dashboard frame.
    ///
    /// This is a pure function of the current `Application` state — call it any time
    /// to get an up-to-date snapshot.
    ///
    /// - Returns: A multi-line `String` ready to be printed to the terminal.
    @MainActor
    public static func render() -> String {
        let style = Application.dependency(\.frameStyling)
        let counter = Application.state(\.counter).value
        let temperature = Application.state(\.temperature).value
        let paused = Application.state(\.paused).value
        let label = Application.storedState(\.dashboardLabel).value

        let width = style.frameWidth
        let inner = width - 2   // width minus two border chars

        var lines: [String] = []

        // Top border
        lines.append(box(corner: style.cornerTopLeft, fill: style.horizontalBorder,
                         corner2: style.cornerTopRight, width: width))

        // Title
        lines.append(paddedRow(text: label, border: style.verticalBorder, inner: inner))
        lines.append(separatorRow(border: style.verticalBorder, fill: style.horizontalBorder, inner: inner))

        // Counter row
        lines.append(paddedRow(text: "Counter : \(counter)", border: style.verticalBorder, inner: inner))

        // Temperature row
        let tempString = String(format: "%.1f", temperature)
        lines.append(paddedRow(text: "Temp    : \(tempString) °C", border: style.verticalBorder, inner: inner))

        // Gauge row
        let gauge = makeGauge(
            value: temperature,
            minimum: minimumTemperature,
            maximum: maximumTemperature,
            width: style.gaugeWidth,
            filled: style.gaugeFilled,
            empty: style.gaugeEmpty
        )
        lines.append(paddedRow(text: "Gauge   : [\(gauge)]", border: style.verticalBorder, inner: inner))

        // Status row
        let statusText = paused ? "Status  : ⏸ PAUSED" : "Status  : ▶ RUNNING"
        lines.append(paddedRow(text: statusText, border: style.verticalBorder, inner: inner))

        lines.append(separatorRow(border: style.verticalBorder, fill: style.horizontalBorder, inner: inner))

        // Help footer — two commands per line
        let helpLines = makeHelpLines(commands: DashboardCommand.allCases.filter { $0 != .quit },
                                      border: style.verticalBorder,
                                      inner: inner)
        lines.append(contentsOf: helpLines)
        lines.append(paddedRow(text: DashboardCommand.quit.label, border: style.verticalBorder, inner: inner))

        // Bottom border
        lines.append(box(corner: style.cornerBottomLeft, fill: style.horizontalBorder,
                         corner2: style.cornerBottomRight, width: width))

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Rendering Helpers

    /// Builds the top or bottom border string.
    private static func box(corner: Character, fill: Character, corner2: Character, width: Int) -> String {
        let bar = String(repeating: fill, count: width - 2)
        return "\(corner)\(bar)\(corner2)"
    }

    /// Builds a content row with border characters and centred/left-padded text.
    private static func paddedRow(text: String, border: Character, inner: Int) -> String {
        let padded = text + String(repeating: " ", count: max(0, inner - text.count))
        let trimmed = String(padded.prefix(inner))
        return "\(border)\(trimmed)\(border)"
    }

    /// Builds a horizontal separator row using repeated fill characters.
    private static func separatorRow(border: Character, fill: Character, inner: Int) -> String {
        let bar = String(repeating: fill, count: inner)
        return "\(border)\(bar)\(border)"
    }

    /// Renders a proportional gauge bar for the given value in [minimum, maximum].
    private static func makeGauge(
        value: Double,
        minimum: Double,
        maximum: Double,
        width: Int,
        filled: Character,
        empty: Character
    ) -> String {
        guard maximum > minimum else { return String(repeating: empty, count: width) }
        let ratio = (value - minimum) / (maximum - minimum)
        let clampedRatio = max(0.0, min(1.0, ratio))
        let filledCount = Int((clampedRatio * Double(width)).rounded())
        let emptyCount = width - filledCount
        return String(repeating: filled, count: filledCount) + String(repeating: empty, count: emptyCount)
    }

    /// Pairs commands side-by-side into rows for the help footer.
    private static func makeHelpLines(
        commands: [DashboardCommand],
        border: Character,
        inner: Int
    ) -> [String] {
        var result: [String] = []
        var index = commands.startIndex
        while index < commands.endIndex {
            let left = commands[index]
            let nextIndex = commands.index(after: index)
            if nextIndex < commands.endIndex {
                let right = commands[nextIndex]
                let half = inner / 2
                let leftPadded = left.label + String(repeating: " ", count: max(0, half - left.label.count))
                let rightText = right.label
                let combined = leftPadded + rightText
                result.append(paddedRow(text: combined, border: border, inner: inner))
                index = commands.index(after: nextIndex)
            } else {
                result.append(paddedRow(text: left.label, border: border, inner: inner))
                index = commands.endIndex
            }
        }
        return result
    }
}
