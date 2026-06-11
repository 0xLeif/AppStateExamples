import SwiftUI
import AppState

// MARK: - App Entry Point

/// Root of the Pomodoro app.
///
/// The engine is initialized lazily on first access from `PomodoroEngine.shared`.
/// No app-level setup is needed — `Application` extensions self-register on first read.
@main
internal struct PomodoroApp: App {

    // MARK: Body

    internal var body: some Scene {
        WindowGroup {
            TimerScreenView()
        }
    }
}
