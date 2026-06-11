import AppState
import Foundation
import TUICore

// MARK: - EntryPoint

/// Interactive terminal live dashboard driven by AppState 3.0.
///
/// Reads single-character commands from stdin and re-renders after each
/// keypress. On Apple platforms, a headless `withObservationTracking` loop
/// also re-renders whenever state changes, demonstrating reactive terminal UI
/// without SwiftUI.
@main
internal struct EntryPoint {

    // MARK: - Main

    internal static func main() async {
        Application.logging(isEnabled: false)
        await runDashboard()
    }

    // MARK: - Run Loop

    @MainActor
    private static func runDashboard() async {
        clearScreen()
        print(DashboardController.render())
        printPrompt()

#if !os(Linux) && !os(Windows)
        // On Apple platforms, wire a reactive observer that re-renders on any state change.
        startReactiveObserver()
#endif

        // Interactive read loop.
        while let line = readLine(strippingNewline: true), let key = line.first {
            guard let command = DashboardCommand.from(key: key) else {
                printPrompt()
                continue
            }

            let shouldContinue = DashboardController.apply(command)
            guard shouldContinue else {
                clearScreen()
                print("Goodbye!")
                return
            }

#if os(Linux) || os(Windows)
            // On Linux/Windows there is no reactive delivery, so re-render immediately.
            clearScreen()
            print(DashboardController.render())
            printPrompt()
#else
            // On Apple the observer fires synchronously via DispatchQueue.main and re-renders.
            // We just re-print the prompt after a brief yield so the cursor looks right.
            await _Concurrency.Task.yield()
            printPrompt()
#endif
        }
    }

    // MARK: - Reactive Observer (Apple only)

#if !os(Linux) && !os(Windows)
    /// Arms a `withObservationTracking` scope over every scalar state field.
    /// When any one changes, clears the screen and re-renders, then re-arms.
    @MainActor
    private static func startReactiveObserver() {
        withObservationTracking {
            // Access all observed state to register dependencies.
            _ = Application.state(\.counter).value
            _ = Application.state(\.temperature).value
            _ = Application.state(\.paused).value
            _ = Application.storedState(\.dashboardLabel).value
        } onChange: {
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    clearScreen()
                    print(DashboardController.render())
                    printPrompt()
                    // Re-arm to keep observing.
                    startReactiveObserver()
                }
            }
        }
    }
#endif

    // MARK: - Terminal Helpers

    /// Clears the terminal screen using ANSI escape codes.
    private static func clearScreen() {
        print("\u{1B}[2J\u{1B}[H", terminator: "")
        fflush(stdout)
    }

    /// Prints the interactive prompt.
    private static func printPrompt() {
        print("\nPress a key (i/d/w/c/p/r/q): ", terminator: "")
        fflush(stdout)
    }
}
