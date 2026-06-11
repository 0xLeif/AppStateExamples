import SwiftUI

// MARK: - TimerRingView

/// A circular progress ring that displays the fraction of time remaining.
///
/// The ring color is driven by `Phase.color`, so it automatically reflects
/// the current Pomodoro phase without any explicit color bindings in the caller.
internal struct TimerRingView: View {

    // MARK: Properties

    /// Progress fraction, from 1.0 (full) to 0.0 (empty). Animatable.
    internal let progress: Double

    /// The phase color used for the foreground arc.
    internal let color: Color

    /// Diameter of the ring, including stroke width.
    internal let diameter: CGFloat

    // MARK: Private Constants

    private let lineWidth: CGFloat = 12

    // MARK: Body

    internal var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
        .frame(width: diameter, height: diameter)
    }
}
