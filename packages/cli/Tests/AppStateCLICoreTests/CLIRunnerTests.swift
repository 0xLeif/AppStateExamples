import XCTest
import AppState
@testable import AppStateCLICore

// MARK: - CLI Runner Tests

/// Covers every public command route, alias, and malformed argument path.
internal final class CLIRunnerTests: XCTestCase {
    @MainActor
    internal override func setUp() async throws {
        var items = Application.fileState(\.items)
        items.value = []

        var selection = Application.state(\.selectedItemIndex)
        selection.value = nil

        var total = Application.storedState(\.totalItemsAdded)
        total.value = 0
    }

    @MainActor
    internal func testMissingCommandAndHelpAliasesReturnUsage() async {
        let noCommand = await CLIRunner.dispatch(arguments: ["appstate-cli"])
        let help = await CLIRunner.dispatch(arguments: ["appstate-cli", "help"])
        let longHelp = await CLIRunner.dispatch(arguments: ["appstate-cli", "--help"])
        let shortHelp = await CLIRunner.dispatch(arguments: ["appstate-cli", "-h"])

        XCTAssertTrue(noCommand.contains("Usage:"))
        XCTAssertEqual(help, noCommand)
        XCTAssertEqual(longHelp, noCommand)
        XCTAssertEqual(shortHelp, noCommand)
    }

    @MainActor
    internal func testAddListAndListAliasDispatch() async {
        let added = await CLIRunner.dispatch(arguments: ["appstate-cli", "add", "Ship", "AppState", "3"])
        let listed = await CLIRunner.dispatch(arguments: ["appstate-cli", "list"])
        let aliased = await CLIRunner.dispatch(arguments: ["appstate-cli", "ls"])

        XCTAssertEqual(added, "Added task [1]: Ship AppState 3")
        XCTAssertTrue(listed.contains("Ship AppState 3"))
        XCTAssertEqual(aliased, listed)
    }

    @MainActor
    internal func testDoneDispatchValidatesAndCompletes() async {
        _ = TaskCommands.add(title: "Verify")

        let missing = await CLIRunner.dispatch(arguments: ["appstate-cli", "done"])
        let malformed = await CLIRunner.dispatch(arguments: ["appstate-cli", "done", "first"])
        let completed = await CLIRunner.dispatch(arguments: ["appstate-cli", "done", "1"])

        XCTAssertEqual(missing, "Usage: done <index>")
        XCTAssertEqual(malformed, "Usage: done <index>")
        XCTAssertEqual(completed, "Done: Verify")
    }

    @MainActor
    internal func testSelectDispatchCoversValidInvalidAndClear() async {
        _ = TaskCommands.add(title: "Selectable")

        let selected = await CLIRunner.dispatch(arguments: ["appstate-cli", "select", "1"])
        let invalid = await CLIRunner.dispatch(arguments: ["appstate-cli", "select", "99"])
        let malformed = await CLIRunner.dispatch(arguments: ["appstate-cli", "select", "first"])
        let missing = await CLIRunner.dispatch(arguments: ["appstate-cli", "select"])

        XCTAssertEqual(selected, "Selected task 1: Selectable")
        XCTAssertEqual(invalid, "Error: no task at index 99.")
        XCTAssertEqual(malformed, "Selection cleared.")
        XCTAssertEqual(missing, "Selection cleared.")
    }

    @MainActor
    internal func testClearAndStatsDispatch() async {
        _ = TaskCommands.add(title: "Tracked")
        _ = TaskCommands.select(index: 1)

        let stats = await CLIRunner.dispatch(arguments: ["appstate-cli", "stats"])
        let cleared = await CLIRunner.dispatch(arguments: ["appstate-cli", "clear"])

        XCTAssertTrue(stats.contains("1 active"))
        XCTAssertTrue(stats.contains("Selected: task 1"))
        XCTAssertEqual(cleared, "Cleared 1 task(s).")
    }

    @MainActor
    internal func testUnknownCommandIncludesCommandAndUsage() async {
        let output = await CLIRunner.dispatch(arguments: ["appstate-cli", "explode"])

        XCTAssertTrue(output.contains("Unknown subcommand 'explode'"))
        XCTAssertTrue(output.contains("Usage:"))
    }

    @MainActor
    internal func testWatchDispatchRunsFiveObservationCycles() async {
        let output = await CLIRunner.dispatch(arguments: ["appstate-cli", "watch"])

        XCTAssertTrue(output.contains("[5/5]"))
        XCTAssertTrue(output.contains("Observation demo complete"))
    }

    @MainActor
    internal func testRunReturnsPrintedResult() async {
        let output = await CLIRunner.run(arguments: ["appstate-cli", "stats"])

        XCTAssertTrue(output.contains("Tasks:"))
    }
}
