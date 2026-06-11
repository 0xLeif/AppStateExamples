import AppState

// MARK: - Application Extension

extension Application {

    // MARK: Counter State

    /// In-memory counter value.  Mutated by increment / decrement buttons in the browser.
    public var counter: State<Int> {
        state(initial: 0, id: "counter")
    }

    // MARK: Next-ID Sequence

    /// Monotonically increasing sequence used to stamp new `TodoItem` ids.
    /// Keeping this in `Application` makes it observable and testable.
    internal var nextTodoID: State<Int> {
        state(initial: 1, id: "nextTodoID")
    }

    // MARK: Todo List State

    /// The current list of to-do items.  An empty array is the initial value so
    /// the DOM renderer always has a well-typed collection to iterate over.
    public var todos: State<[TodoItem]> {
        state(initial: [], id: "todos")
    }

    // MARK: Dependencies

    /// Injected counter formatter — swap out in tests via `Application.override`.
    public var counterFormatter: Dependency<any CounterFormatting> {
        dependency(DefaultCounterFormatter(), id: "counterFormatter")
    }
}
