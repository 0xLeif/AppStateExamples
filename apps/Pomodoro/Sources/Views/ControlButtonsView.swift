import SwiftUI

// MARK: - ControlButtonsView

/// Start/Pause and Reset control buttons.
///
/// The engine is called directly here — views never mutate `Application` state themselves.
internal struct ControlButtonsView: View {

    // MARK: Properties

    internal let isRunning: Bool
    internal let phaseColor: Color

    // MARK: Body

    internal var body: some View {
        HStack(spacing: 24) {
            primaryButton
            resetButton
        }
    }

    // MARK: Primary (Start / Pause)

    private var primaryButton: some View {
        Button {
            if isRunning {
                PomodoroEngine.shared.pause()
            } else {
                PomodoroEngine.shared.start()
            }
        } label: {
            Label(
                isRunning ? "Pause" : "Start",
                systemImage: isRunning ? "pause.fill" : "play.fill"
            )
            .font(.headline)
            .frame(minWidth: 110)
        }
        .buttonStyle(.borderedProminent)
        .tint(phaseColor)
        .animation(.easeInOut(duration: 0.2), value: isRunning)
    }

    // MARK: Reset

    private var resetButton: some View {
        Button {
            PomodoroEngine.shared.reset()
        } label: {
            Label("Reset", systemImage: "arrow.counterclockwise")
                .font(.headline)
                .frame(minWidth: 90)
        }
        .buttonStyle(.bordered)
        .tint(.secondary)
    }
}
