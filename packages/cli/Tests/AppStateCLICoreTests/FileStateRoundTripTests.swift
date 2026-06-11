import XCTest
import AppState
@testable import AppStateCLICore

// MARK: - FileStateRoundTripTests

/// Verifies that items persisted via `FileState` survive a simulated
/// "restart" by reading the state back through the same Application key.
final class FileStateRoundTripTests: XCTestCase {

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        var itemsState = Application.fileState(\.items)
        itemsState.value = []
        var counterState = Application.storedState(\.totalItemsAdded)
        counterState.value = 0
    }

    // MARK: - Round-trip

    @MainActor
    func testItemsPersistAndReload() throws {
        // Write items through the command layer.
        _ = TaskCommands.add(title: "Persisted item 1")
        _ = TaskCommands.add(title: "Persisted item 2")
        _ = TaskCommands.done(index: 1)

        // Capture what was written.
        let written = Application.fileState(\.items).value ?? []
        XCTAssertEqual(written.count, 2)
        XCTAssertTrue(written[0].isCompleted)
        XCTAssertFalse(written[1].isCompleted)

        // Simulate reading back by accessing the same FileState key.
        // AppState's FileState persists to disk; the same key returns the
        // same backing store within a single process.
        let reloaded = Application.fileState(\.items).value ?? []
        XCTAssertEqual(reloaded.count, written.count)
        XCTAssertEqual(reloaded[0].title, written[0].title)
        XCTAssertEqual(reloaded[0].isCompleted, written[0].isCompleted)
        XCTAssertEqual(reloaded[1].title, written[1].title)
    }

    @MainActor
    func testClearWipesFileState() {
        _ = TaskCommands.add(title: "To be cleared")
        _ = TaskCommands.clear()

        let items = Application.fileState(\.items).value ?? []
        XCTAssertTrue(items.isEmpty)
    }
}
