import SwiftUI

// MARK: - TimerDisplayView

/// The large MM:SS countdown label overlaid on the progress ring.
internal struct TimerDisplayView: View {

    // MARK: Properties

    /// Seconds remaining to display.
    internal let remainingSeconds: Int

    /// Phase color applied to the time text for visual consistency.
    internal let color: Color

    // MARK: Body

    internal var body: some View {
        Text(formattedTime)
            .font(.system(size: 56, weight: .semibold, design: .monospaced))
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.25), value: remainingSeconds)
    }

    // MARK: Private

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
