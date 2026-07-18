import AppState
import Foundation

// MARK: - CLIRunner

/// Top-level argument dispatcher for `appstate-cli`.
///
/// Parses `CommandLine.arguments` (or a synthetic array in tests) and routes
/// to the appropriate `TaskCommands` handler. Keeping this in `AppStateCLICore`
/// means the routing logic can be covered by unit tests.
public enum CLIRunner: Sendable {

    // MARK: - Output Collector

    @MainActor
    fileprivate final class OutputCollector {
        private var lines: [String] = []

        fileprivate init() {}

        fileprivate func append(_ line: String) {
            lines.append(line)
        }

        fileprivate var output: String {
            lines.joined(separator: "\n")
        }
    }

    // MARK: - Public Interface

    /// Runs the CLI with the provided argument vector and prints to stdout.
    ///
    /// - Parameter arguments: Typically `CommandLine.arguments`; element 0 is
    ///   the executable path and is ignored.
    @MainActor
    @discardableResult
    public static func run(arguments: [String]) async -> String {
        let result = await dispatch(arguments: arguments)
        print(result)
        return result
    }

    // MARK: - Dispatch

    /// Routes arguments to a handler and returns the output string.
    ///
    /// Separated from `run` so tests can capture output without printing.
    ///
    /// - Parameter arguments: Full argument vector including executable name.
    /// - Returns: Single- or multi-line result string ready to display.
    @MainActor
    public static func dispatch(arguments: [String]) async -> String {
        // Drop argv[0] (executable path).
        let args = Array(arguments.dropFirst())

        guard let subcommand = args.first else {
            return usage()
        }

        switch subcommand {
        case "add":
            let title = args.dropFirst().joined(separator: " ")
            return TaskCommands.add(title: title)

        case "list", "ls":
            return TaskCommands.list()

        case "done":
            guard
                let raw = args.dropFirst().first,
                let index = Int(raw)
            else {
                return "Usage: done <index>"
            }
            return TaskCommands.done(index: index)

        case "select":
            if let raw = args.dropFirst().first, let index = Int(raw) {
                return TaskCommands.select(index: index)
            }
            return TaskCommands.select(index: nil)

        case "clear":
            return TaskCommands.clear()

        case "stats":
            return TaskCommands.stats()

        case "watch":
            return await runWatch()

        case "help", "--help", "-h":
            return usage()

        default:
            return "Unknown subcommand '\(subcommand)'.\n\n\(usage())"
        }
    }

    // MARK: - Watch

    /// Runs the headless observation demo and collects its output lines.
    @MainActor
    private static func runWatch() async -> String {
        let collector = OutputCollector()
        await ObservationDemo.run(mutationCount: 5) { [collector] line in
            collector.append(line)
        }

        return collector.output
    }

    // MARK: - Usage

    private static func usage() -> String {
        """
        appstate-cli — Task Tracker (AppState 3.0 Demo)

        Usage:
          appstate-cli add <title>     Add a new task
          appstate-cli list            List all tasks
          appstate-cli done <index>    Mark a task complete (1-based)
          appstate-cli select <index>  Select a task for the session
          appstate-cli clear           Remove all tasks
          appstate-cli stats           Show session and lifetime stats
          appstate-cli watch           Headless observation demo (AppState 3.0)
          appstate-cli help            Show this message

        State storage:
          Tasks persist to ~/Library/Application Support/ (FileState)
          Lifetime counter persists to UserDefaults (StoredState)
          Selected index is in-memory only (State)
        """
    }
}
