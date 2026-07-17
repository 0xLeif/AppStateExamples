import XCTest
import AppState
@testable import AppStateCLICore

// MARK: - TaskCommandTests

internal final class TaskCommandTests: XCTestCase {

    // MARK: - Setup / Teardown

    @MainActor
    internal override func setUp() async throws {
        // Start each test with a clean slate.
        var itemsState = Application.fileState(\.items)
        itemsState.value = []
        var selectionState = Application.state(\.selectedItemIndex)
        selectionState.value = nil
        var counterState = Application.storedState(\.totalItemsAdded)
        counterState.value = 0
    }

    // MARK: - add

    @MainActor
    internal func testAddCreatesItem() {
        let result = TaskCommands.add(title: "Write tests")
        XCTAssertTrue(result.contains("Added task [1]"))
        XCTAssertTrue(result.contains("Write tests"))

        let items = Application.fileState(\.items).value ?? []
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].title, "Write tests")
        XCTAssertFalse(items[0].isCompleted)
    }

    @MainActor
    internal func testAddMultipleItems() {
        _ = TaskCommands.add(title: "First")
        _ = TaskCommands.add(title: "Second")
        _ = TaskCommands.add(title: "Third")

        let items = Application.fileState(\.items).value ?? []
        XCTAssertEqual(items.count, 3)
    }

    @MainActor
    internal func testAddEmptyTitleReturnsError() {
        let result = TaskCommands.add(title: "   ")
        XCTAssertTrue(result.lowercased().contains("error"))

        let items = Application.fileState(\.items).value ?? []
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    internal func testAddIncrementsLifetimeCounter() {
        _ = TaskCommands.add(title: "Item A")
        _ = TaskCommands.add(title: "Item B")

        let total = Application.storedState(\.totalItemsAdded).value
        XCTAssertEqual(total, 2)
    }

    @MainActor
    internal func testAddTrimsWhitespace() {
        let result = TaskCommands.add(title: "  Trim me  ")
        let items = Application.fileState(\.items).value ?? []

        XCTAssertEqual(result, "Added task [1]: Trim me")
        XCTAssertEqual(items.first?.title, "Trim me")
    }

    // MARK: - list

    @MainActor
    internal func testListEmptyReturnsHint() {
        let result = TaskCommands.list()
        XCTAssertTrue(result.contains("No tasks yet"))
    }

    @MainActor
    internal func testListShowsAllItems() {
        _ = TaskCommands.add(title: "Alpha")
        _ = TaskCommands.add(title: "Beta")

        let result = TaskCommands.list()
        XCTAssertTrue(result.contains("Alpha"))
        XCTAssertTrue(result.contains("Beta"))
        XCTAssertTrue(result.contains("[ ]"))
    }

    @MainActor
    internal func testListShowsCompletedMarkerAndLifetimeTotal() {
        _ = TaskCommands.add(title: "Complete me")
        _ = TaskCommands.done(index: 1)

        let result = TaskCommands.list()

        XCTAssertTrue(result.contains("[x] Complete me"))
        XCTAssertTrue(result.contains("1 added all-time"))
    }

    // MARK: - done

    @MainActor
    internal func testDoneMarksItemComplete() {
        _ = TaskCommands.add(title: "Ship it")

        let result = TaskCommands.done(index: 1)
        XCTAssertTrue(result.contains("Done"))
        XCTAssertTrue(result.contains("Ship it"))

        let items = Application.fileState(\.items).value ?? []
        XCTAssertTrue(items[0].isCompleted)
    }

    @MainActor
    internal func testDoneOutOfRangeReturnsError() {
        _ = TaskCommands.add(title: "Only item")

        let result = TaskCommands.done(index: 99)
        XCTAssertTrue(result.lowercased().contains("error"))
    }

    @MainActor
    internal func testDoneAlreadyCompleteReturnsMessage() {
        _ = TaskCommands.add(title: "Repeat done")
        _ = TaskCommands.done(index: 1)

        let result = TaskCommands.done(index: 1)
        XCTAssertTrue(result.contains("already done"))
    }

    @MainActor
    internal func testDoneClearsMatchingSelectionOnly() {
        _ = TaskCommands.add(title: "First")
        _ = TaskCommands.add(title: "Second")
        _ = TaskCommands.select(index: 2)

        _ = TaskCommands.done(index: 1)
        XCTAssertEqual(Application.state(\.selectedItemIndex).value, 2)

        _ = TaskCommands.done(index: 2)
        XCTAssertNil(Application.state(\.selectedItemIndex).value)
    }

    @MainActor
    internal func testDoneRejectsZeroAndNegativeIndices() {
        _ = TaskCommands.add(title: "Only")

        XCTAssertTrue(TaskCommands.done(index: 0).contains("Error"))
        XCTAssertTrue(TaskCommands.done(index: -1).contains("Error"))
    }

    // MARK: - select

    @MainActor
    internal func testSelectSetsAndClearsSelection() {
        _ = TaskCommands.add(title: "Selectable")

        XCTAssertEqual(TaskCommands.select(index: 1), "Selected task 1: Selectable")
        XCTAssertEqual(Application.state(\.selectedItemIndex).value, 1)
        XCTAssertEqual(TaskCommands.select(index: nil), "Selection cleared.")
        XCTAssertNil(Application.state(\.selectedItemIndex).value)
    }

    @MainActor
    internal func testSelectRejectsOutOfRangeIndicesWithoutChangingSelection() {
        _ = TaskCommands.add(title: "Selectable")
        _ = TaskCommands.select(index: 1)

        XCTAssertEqual(TaskCommands.select(index: 0), "Error: no task at index 0.")
        XCTAssertEqual(TaskCommands.select(index: 2), "Error: no task at index 2.")
        XCTAssertEqual(Application.state(\.selectedItemIndex).value, 1)
    }

    // MARK: - clear

    @MainActor
    internal func testClearRemovesAllItems() {
        _ = TaskCommands.add(title: "A")
        _ = TaskCommands.add(title: "B")

        let result = TaskCommands.clear()
        XCTAssertTrue(result.contains("Cleared 2"))

        let items = Application.fileState(\.items).value ?? []
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    internal func testClearResetsSelectedIndex() {
        _ = TaskCommands.add(title: "Selected one")
        _ = TaskCommands.select(index: 1)
        XCTAssertEqual(Application.state(\.selectedItemIndex).value, 1)

        _ = TaskCommands.clear()
        XCTAssertNil(Application.state(\.selectedItemIndex).value)
    }

    @MainActor
    internal func testClearEmptyCollectionReportsZero() {
        XCTAssertEqual(TaskCommands.clear(), "Cleared 0 task(s).")
    }

    // MARK: - stats

    @MainActor
    internal func testStatsCoversCompletedAndUnselectedState() {
        _ = TaskCommands.add(title: "Done")
        _ = TaskCommands.add(title: "Open")
        _ = TaskCommands.done(index: 1)

        let result = TaskCommands.stats()

        XCTAssertEqual(result, "Tasks: 2 active, 1 completed, 2 added all-time. Selected: none.")
    }
}
