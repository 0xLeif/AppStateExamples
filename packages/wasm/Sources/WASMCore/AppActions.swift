import AppState

// MARK: - AppActions

/// Pure, side-effect-free mutations on `Application` state.
///
/// All functions are `@MainActor` because `Application.notifyChange()` asserts
/// it is called from the main thread, and wasm runs single-threaded so this is
/// always satisfied.
@MainActor
public enum AppActions {

    // MARK: Counter

    /// Increments the counter by one.
    public static func increment() {
        var counter = Application.state(\.counter)
        counter.value += 1
    }

    /// Decrements the counter by one.
    public static func decrement() {
        var counter = Application.state(\.counter)
        counter.value -= 1
    }

    /// Resets the counter to zero.
    public static func resetCounter() {
        var counter = Application.state(\.counter)
        counter.value = 0
    }

    // MARK: Todos

    /// Appends a new `TodoItem` with the given text.
    ///
    /// - Parameter text: Trimmed user input; ignored when empty.
    public static func addTodo(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        var nextID = Application.state(\.nextTodoID)
        let id = nextID.value
        nextID.value = id + 1

        var todos = Application.state(\.todos)
        todos.value.append(TodoItem(id: id, text: trimmed))
    }

    /// Removes the `TodoItem` identified by `id`, if present.
    ///
    /// - Parameter id: The `TodoItem.id` to remove.
    public static func removeTodo(id: Int) {
        var todos = Application.state(\.todos)
        todos.value.removeAll { $0.id == id }
    }

    // MARK: Formatted reads

    /// Returns the display label for the current counter, using the injected formatter.
    public static func counterLabel() -> String {
        let formatter = Application.dependency(\.counterFormatter)
        let count = Application.state(\.counter).value
        return formatter.label(for: count)
    }
}
