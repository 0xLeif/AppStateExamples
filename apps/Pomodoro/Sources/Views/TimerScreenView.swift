import SwiftUI
import AppState

// MARK: - TimerScreenView

/// The primary screen of the Pomodoro app.
///
/// Observes all live timer state via `@AppState`. The ring, label, and buttons
/// all update automatically when the engine mutates `Application` state.
internal struct TimerScreenView: View {

    // MARK: AppState Observation

    @AppState(\.phase) private var phase: Phase
    @AppState(\.remainingSeconds) private var remainingSeconds: Int
    @AppState(\.isRunning) private var isRunning: Bool
    @AppState(\.workMinutes) private var workMinutes: Int
    @AppState(\.completedSessions) private var completedSessions: Int

    // MARK: Navigation State

    @State private var isShowingSettings = false

    // MARK: Body

    internal var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                phaseLabelView

                ringAndTimerStack

                ControlButtonsView(
                    isRunning: isRunning,
                    phaseColor: phase.color
                )

                SessionBadgeView(completedSessions: completedSessions)

                Spacer()
            }
            .padding()
            .background(backgroundGradient)
            .navigationTitle("Pomodoro")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: Subviews

    private var phaseLabelView: some View {
        HStack(spacing: 8) {
            Image(systemName: phase.symbolName)
                .font(.title3)
                .foregroundStyle(phase.color)
            Text(phase.label)
                .font(.title3.weight(.medium))
                .foregroundStyle(phase.color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(phase.color.opacity(0.12), in: Capsule())
        .animation(.easeInOut(duration: 0.3), value: phase)
    }

    private var ringAndTimerStack: some View {
        ZStack {
            TimerRingView(
                progress: ringProgress,
                color: phase.color,
                diameter: 260
            )

            TimerDisplayView(
                remainingSeconds: remainingSeconds,
                color: phase.color
            )
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                phase.color.opacity(0.05),
                phase.color.opacity(0.02),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: phase)
    }

    // MARK: Computed

    private var ringProgress: Double {
        let total = Double(workMinutes * 60)
        guard total > 0 else { return 1 }
        return Double(remainingSeconds) / total
    }
}
