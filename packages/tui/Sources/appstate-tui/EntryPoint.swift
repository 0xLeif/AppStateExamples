import AppState
import Foundation
import TUICore

// MARK: - EntryPoint

/// Interactive terminal live dashboard driven by AppState 3.0.
///
/// **Interactive mode** (default, no arguments): reads single-character commands
/// from stdin and re-renders synchronously after each command. Rendering is always
/// deterministic — N commands always produce exactly N state mutations.
///
/// **Demo mode** (`swift run appstate-tui demo`): performs a scripted sequence of
/// state mutations while a headless `withObservationTracking` observer counts
/// reactions. Proves live observation works without interactive-input races.
@main
internal struct EntryPoint {

    // MARK: - Main

    internal static func main() async {
        Application.logging(isEnabled: false)

        let args = CommandLine.arguments.dropFirst()
        if args.first == "demo" {
            await runDemo()
        } else {
            await runDashboard()
        }
    }

    // MARK: - Interactive Mode

    /// Reads commands from stdin and applies them one-by-one, rendering synchronously
    /// after each command.
    ///
    /// Rendering is intentionally synchronous — no GCD, no `Task.yield()` — so that
    /// piped input always produces a deterministic final frame.
    @MainActor
    private static func runDashboard() async {
        clearScreen()
        print(DashboardController.render())
        printPrompt()

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

            // Render synchronously on every platform: no GCD, no Task.yield().
            // This guarantees N commands → N applied mutations → deterministic output.
            clearScreen()
            print(DashboardController.render())
            printPrompt()
        }
    }

    // MARK: - Demo Mode (Observation Showcase)

    /// Demonstrates live `withObservationTracking` reactions without interactive-input races.
    ///
    /// Each mutation is applied only *after* the previous reaction has been confirmed,
    /// using an `AsyncStream` as a rendezvous channel between the `onChange` callback
    /// and the `@MainActor` mutation loop. This makes the demo fully deterministic:
    /// N mutations always produce exactly N observer reactions, each logged with the
    /// live state value at the moment of reaction.
    ///
    /// Re-arming is done via `Task { @MainActor in }` (structured concurrency) — no GCD.
#if !os(Linux) && !os(Windows)
    @MainActor
    private static func runDemo() async {
        print("=== AppState Observation Demo ===\n")

        // Reset all state to known defaults so the demo is self-contained
        // regardless of prior interactive-session values.
        DashboardController.apply(.reset)

        let script: [DashboardCommand] = [.increment, .increment, .increment, .warmer, .togglePause]
        let expectedReactions = script.count

        print("Script: \(script.map(\.label).joined(separator: ", "))")
        print("Expected observer reactions: \(expectedReactions)\n")

        // AsyncStream acts as a rendezvous: onChange yields one token per reaction,
        // and the mutation loop waits for each token before applying the next command.
        // This makes the order of mutation → reaction → next-mutation strictly sequential.
        var continuation: AsyncStream<Void>.Continuation?
        let reactions = AsyncStream<Void> { cont in
            continuation = cont
        }
        guard let cont = continuation else { return }

        // Yield once after reset to let any pending initialization Tasks run (AppState's
        // non-test path can schedule Task { @MainActor in setValue() } on first access).
        for _ in 0 ..< 4 { await Task.yield() }

        var reactionCount = 0

        // Arm the first tracking scope.
        armObserver(continuation: cont, armed: SharedBool())

        // Use a persistent iterator so each `await iter.next()` consumes exactly one
        // token from the stream — no risk of `.prefix(1)` creating separate iterators
        // that race or skip tokens.
        var iter = reactions.makeAsyncIterator()

        for command in script {
            DashboardController.apply(command)

            // Wait for the observer to react before moving to the next mutation.
            // Because we're on @MainActor, this suspend point gives the re-arm Task
            // scheduled by onChange a chance to execute, ensuring the next mutation
            // always has an active tracking scope.
            guard await iter.next() != nil else { break }
            reactionCount += 1
            let counter = Application.state(\.counter).value
            let temperature = Application.state(\.temperature).value
            let paused = Application.state(\.paused).value
            print("  Reaction \(reactionCount): counter=\(counter)  temp=\(temperature)°C  paused=\(paused)")
        }

        cont.finish()

        print("\nObserver reacted \(reactionCount) time(s) to \(expectedReactions) mutation(s).")
        print("\n--- Final Frame ---\n")
        print(DashboardController.render())
        print("\nDemo complete. Observer fired \(reactionCount)/\(expectedReactions) time(s).")
    }

    /// Arms one `withObservationTracking` scope over all scalar dashboard state.
    ///
    /// When `onChange` fires the continuation yields a token (signalling the demo loop),
    /// then a `Task { @MainActor in }` re-arms the next scope. Uses structured concurrency
    /// throughout — no GCD.
    ///
    /// - Parameters:
    ///   - continuation: The `AsyncStream` continuation that signals each reaction.
    ///   - armed: A shared flag used to prevent double-firing within one scope lifetime.
    @MainActor
    private static func armObserver(
        continuation: AsyncStream<Void>.Continuation,
        armed: SharedBool
    ) {
        armed.set(true)
        withObservationTracking {
            _ = Application.state(\.counter).value
            _ = Application.state(\.temperature).value
            _ = Application.state(\.paused).value
        } onChange: { [armed, continuation] in
            // onChange is @Sendable; armed guards against spurious double-fires.
            guard armed.compareAndSet(expected: true, newValue: false) else { return }
            continuation.yield()
            // Re-arm via structured concurrency — NOT DispatchQueue.
            Task { @MainActor in
                armObserver(continuation: continuation, armed: SharedBool())
            }
        }
    }
#else
    /// Stub for Linux/Windows where `withObservationTracking` onChange is not delivered.
    @MainActor
    private static func runDemo() async {
        print("=== AppState Observation Demo ===\n")
        print("Note: withObservationTracking onChange is not available on this platform.")
        print("Applying scripted mutations and rendering final frame...\n")

        DashboardController.apply(.reset)
        let script: [DashboardCommand] = [.increment, .increment, .increment, .warmer, .togglePause]
        for command in script {
            DashboardController.apply(command)
        }

        print(DashboardController.render())
        print("\nDemo complete.")
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

// MARK: - SharedBool

/// A lock-guarded Boolean that supports an atomic compare-and-set operation.
///
/// Used to guard `withObservationTracking` `onChange` closures against
/// spurious double-fires within a single tracking scope lifetime.
///
/// `@unchecked Sendable` is justified: all mutation goes through `NSLock`,
/// making all accesses data-race-free.
private final class SharedBool: @unchecked Sendable {

    private let lock = NSLock()
    private var _value: Bool

    /// Creates a new `SharedBool` with the given initial value.
    init(_ initial: Bool = false) {
        _value = initial
    }

    /// Sets the stored value unconditionally.
    func set(_ newValue: Bool) {
        lock.lock()
        defer { lock.unlock() }
        _value = newValue
    }

    /// Atomically sets the value to `newValue` only if the current value equals `expected`.
    ///
    /// - Returns: `true` if the swap occurred; `false` if the current value did not match.
    func compareAndSet(expected: Bool, newValue: Bool) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard _value == expected else { return false }
        _value = newValue
        return true
    }
}
