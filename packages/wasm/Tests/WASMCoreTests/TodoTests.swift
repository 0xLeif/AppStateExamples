import XCTest
import AppState
import Observation
@testable import WASMCore

// MARK: - TodoTests

/// Tests for the todo list state mutations in `AppActions`.
///
/// Each test resets shared state in `setUp` to remain isolated and
/// order-independent.  These run on the host toolchain — no WASM SDK required.
internal final class TodoTests: XCTestCase {

    // MARK: - Setup

    @MainActor
    internal override func setUp() async throws {
        var todos = Application.state(\.todos)
        todos.value = []
        var nextID = Application.state(\.nextTodoID)
        nextID.value = 1
    }

    // MARK: - addTodo

    @MainActor
    internal func testAddTodoAppendsItemWithTrimmedText() async {
        AppActions.addTodo(text: "  Ship WASM example  ")

        let items = Application.state(\.todos).value
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].text, "Ship WASM example")
        XCTAssertEqual(items[0].id, 1)
    }

    @MainActor
    internal func testAddTodoIgnoresWhitespaceOnlyInput() async {
        AppActions.addTodo(text: "   ")
        AppActions.addTodo(text: "")

        XCTAssertTrue(Application.state(\.todos).value.isEmpty)
    }

    @MainActor
    internal func testAddTodoAssignsMonotonicallyIncreasingIDs() async {
        var nextID = Application.state(\.nextTodoID)
        nextID.value = 10

        AppActions.addTodo(text: "First")
        AppActions.addTodo(text: "Second")
        AppActions.addTodo(text: "Third")

        let ids = Application.state(\.todos).value.map(\.id)
        XCTAssertEqual(ids, [10, 11, 12])
    }

    @MainActor
    internal func testAddTodoIncrementsNextID() async {
        AppActions.addTodo(text: "Item")
        XCTAssertEqual(Application.state(\.nextTodoID).value, 2)
    }

    @MainActor
    internal func testAddTodoMultipleItems() async {
        AppActions.addTodo(text: "Alpha")
        AppActions.addTodo(text: "Beta")
        AppActions.addTodo(text: "Gamma")

        let items = Application.state(\.todos).value
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items.map(\.text), ["Alpha", "Beta", "Gamma"])
    }

    // MARK: - removeTodo

    @MainActor
    internal func testRemoveTodoRemovesOnlyMatchingItem() async {
        var todos = Application.state(\.todos)
        todos.value = [
            TodoItem(id: 1, text: "Keep me"),
            TodoItem(id: 2, text: "Remove me"),
            TodoItem(id: 3, text: "Keep me too")
        ]

        AppActions.removeTodo(id: 2)

        let remaining = Application.state(\.todos).value
        XCTAssertEqual(remaining.count, 2)
        XCTAssertEqual(remaining.map(\.id), [1, 3])
    }

    @MainActor
    internal func testRemoveTodoIsNoOpForUnknownID() async {
        var todos = Application.state(\.todos)
        todos.value = [TodoItem(id: 5, text: "Existing")]
        AppActions.removeTodo(id: 999)
        XCTAssertEqual(Application.state(\.todos).value.count, 1)
    }

    @MainActor
    internal func testRemoveTodoFromEmptyListIsNoOp() async {
        AppActions.removeTodo(id: 1)
        XCTAssertTrue(Application.state(\.todos).value.isEmpty)
    }

    @MainActor
    internal func testRemoveTodoAllItems() async {
        var todos = Application.state(\.todos)
        todos.value = [
            TodoItem(id: 1, text: "A"),
            TodoItem(id: 2, text: "B")
        ]
        AppActions.removeTodo(id: 1)
        AppActions.removeTodo(id: 2)
        XCTAssertTrue(Application.state(\.todos).value.isEmpty)
    }

    // MARK: - Observation

    // Observation delivery is verified on Apple platforms only (see CounterTests).
    #if !os(Linux) && !os(Windows)
    @MainActor
    internal func testTodosStateChangeFiresObservationCallback() async {
        let fired = FiredBox()

        withObservationTracking {
            _ = Application.state(\.todos).value
        } onChange: {
            fired.increment()
        }

        AppActions.addTodo(text: "Trigger observation")
        await Task.yield()

        XCTAssertEqual(fired.count, 1)
    }

    @MainActor
    internal func testRemoveAlsoFiresObservationCallback() async {
        var todos = Application.state(\.todos)
        todos.value = [TodoItem(id: 1, text: "Existing")]

        let fired = FiredBox()

        withObservationTracking {
            _ = Application.state(\.todos).value
        } onChange: {
            fired.increment()
        }

        AppActions.removeTodo(id: 1)
        await Task.yield()

        XCTAssertEqual(fired.count, 1)
    }

    @MainActor
    internal func testRearmCatchesSubsequentMutations() async {
        let observer = RearmingTodoObserver(limit: 2)
        observer.start()

        AppActions.addTodo(text: "First")
        await Task.yield()
        await Task.yield()

        AppActions.addTodo(text: "Second")
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(observer.count, 2)
        XCTAssertEqual(observer.snapshots[0].count, 1)
        XCTAssertEqual(observer.snapshots[1].count, 2)
    }
    #endif
}

#if !os(Linux) && !os(Windows)

// MARK: - FiredBox

/// Thread-safe counter for capturing `withObservationTracking` reactions from a
/// `@Sendable` `onChange` closure.
private final class FiredBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

// MARK: - RearmingTodoObserver

/// A self-re-arming headless observer of `Application.todos` that records a
/// snapshot on each change until `limit` is reached. Capturing `self` (a
/// `@MainActor` class) inside the `@Sendable` `onChange` closure is allowed.
@MainActor
private final class RearmingTodoObserver {
    private(set) var snapshots: [[TodoItem]] = []
    private let limit: Int

    var count: Int { snapshots.count }

    init(limit: Int) {
        self.limit = limit
    }

    func start() {
        arm()
    }

    private func arm() {
        withObservationTracking {
            _ = Application.state(\.todos).value
        } onChange: {
            Task { @MainActor [weak self] in
                self?.handleChange()
            }
        }
    }

    private func handleChange() {
        snapshots.append(Application.state(\.todos).value)
        if snapshots.count < limit {
            arm()
        }
    }
}

#endif
