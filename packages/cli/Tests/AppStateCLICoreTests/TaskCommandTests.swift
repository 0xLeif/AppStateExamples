import XCTest
import AppState
@testable import AppStateCLICore

// MARK: - TaskCommandTests

final class TaskCommandTests: XCTestCase {

    // MARK: - Setup / Teardown

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
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
    func testAddCreatesItem() {
        let result = TaskCommands.add(title: "Write tests")
        XCTAssertTrue(result.contains("Added task [1]"))
        XCTAssertTrue(result.contains("Write tests"))

        let items = Application.fileState(\.items).value ?? []
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].title, "Write tests")
        XCTAssertFalse(items[0].isCompleted)
    }

    @MainActor
    func testAddMultipleItems() {
        _ = TaskCommands.add(title: "First")
        _ = TaskCommands.add(title: "Second")
        _ = TaskCommands.add(title: "Third")

        let items = Application.fileState(\.items).value ?? []
        XCTAssertEqual(items.count, 3)
    }

    @MainActor
    func testAddEmptyTitleReturnsError() {
        let result = TaskCommands.add(title: "   ")
        XCTAssertTrue(result.lowercased().contains("error"))

        let items = Application.fileState(\.items).value ?? []
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    func testAddIncrementsLifetimeCounter() {
        _ = TaskCommands.add(title: "Item A")
        _ = TaskCommands.add(title: "Item B")

        let total = Application.storedState(\.totalItemsAdded).value
        XCTAssertEqual(total, 2)
    }

    // MARK: - list

    @MainActor
    func testListEmptyReturnsHint() {
        let result = TaskCommands.list()
        XCTAssertTrue(result.contains("No tasks yet"))
    }

    @MainActor
    func testListShowsAllItems() {
        _ = TaskCommands.add(title: "Alpha")
        _ = TaskCommands.add(title: "Beta")

        let result = TaskCommands.list()
        XCTAssertTrue(result.contains("Alpha"))
        XCTAssertTrue(result.contains("Beta"))
        XCTAssertTrue(result.contains("[ ]"))
    }

    // MARK: - done

    @MainActor
    func testDoneMarksItemComplete() {
        _ = TaskCommands.add(title: "Ship it")

        let result = TaskCommands.done(index: 1)
        XCTAssertTrue(result.contains("Done"))
        XCTAssertTrue(result.contains("Ship it"))

        let items = Application.fileState(\.items).value ?? []
        XCTAssertTrue(items[0].isCompleted)
    }

    @MainActor
    func testDoneOutOfRangeReturnsError() {
        _ = TaskCommands.add(title: "Only item")

        let result = TaskCommands.done(index: 99)
        XCTAssertTrue(result.lowercased().contains("error"))
    }

    @MainActor
    func testDoneAlreadyCompleteReturnsMessage() {
        _ = TaskCommands.add(title: "Repeat done")
        _ = TaskCommands.done(index: 1)

        let result = TaskCommands.done(index: 1)
        XCTAssertTrue(result.contains("already done"))
    }

    // MARK: - clear

    @MainActor
    func testClearRemovesAllItems() {
        _ = TaskCommands.add(title: "A")
        _ = TaskCommands.add(title: "B")

        let result = TaskCommands.clear()
        XCTAssertTrue(result.contains("Cleared 2"))

        let items = Application.fileState(\.items).value ?? []
        XCTAssertTrue(items.isEmpty)
    }

    @MainActor
    func testClearResetsSelectedIndex() {
        _ = TaskCommands.add(title: "Selected one")
        _ = TaskCommands.select(index: 1)
        XCTAssertEqual(Application.state(\.selectedItemIndex).value, 1)

        _ = TaskCommands.clear()
        XCTAssertNil(Application.state(\.selectedItemIndex).value)
    }
}
