import AppStateCLICore
import Foundation

// MARK: - Entry Point

// AppState requires mutations on the main actor. We wrap the entire
// program in a `@MainActor` async block and suspend the main thread
// until it completes using a semaphore.

let semaphore = DispatchSemaphore(value: 0)

Task { @MainActor in
    defer { semaphore.signal() }
    await CLIRunner.run(arguments: CommandLine.arguments)
}

semaphore.wait()
