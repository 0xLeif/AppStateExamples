import AppState
import Foundation

// MARK: - TaskCommands

/// Namespace for all task-tracker command implementations.
///
/// Each function returns a human-readable output string and is safe to call
/// from any `@MainActor` context. Keeping the return value as a `String`
/// makes each handler trivially testable without capturing stdout.
public enum TaskCommands: Sendable {

    // MARK: - add

    /// Appends a new item with the given title and returns a confirmation line.
    ///
    /// Side-effects (all on main thread, required by AppState):
    /// - Appends to `Application.items` (FileState)
    /// - Increments `Application.totalItemsAdded` (StoredState)
    ///
    /// - Parameter title: Non-empty item description.
    /// - Returns: Human-readable confirmation, or an error description.
    @MainActor
    public static func add(title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return "Error: title must not be empty."
        }

        let generator = Application.dependency(\.idGenerator)
        let clock = Application.dependency(\.clock)
        let newItem = TodoItem(id: generator.newID(), title: trimmed, createdAt: clock.now())

        // Capture to a `var` so the mutating setter can write back to the cache.
        var itemsState = Application.fileState(\.items)
        var current = itemsState.value ?? []
        current.append(newItem)
        itemsState.value = current

        var counter = Application.storedState(\.totalItemsAdded)
        counter.value += 1

        return "Added task [\(current.count)]: \(trimmed)"
    }

    // MARK: - list

    /// Returns a formatted table of all items, or a hint if none exist.
    ///
    /// - Returns: Multi-line string suitable for printing to stdout.
    @MainActor
    public static func list() -> String {
        let items = Application.fileState(\.items).value ?? []
        guard !items.isEmpty else {
            return "No tasks yet. Use `add <title>` to create one."
        }

        let lines: [String] = items.enumerated().map { index, item in
            let marker = item.isCompleted ? "[x]" : "[ ]"
            return "  \(index + 1). \(marker) \(item.title)"
        }

        let total = Application.storedState(\.totalItemsAdded).value
        let header = "Tasks (\(items.count) shown, \(total) added all-time):"
        return ([header] + lines).joined(separator: "\n")
    }

    // MARK: - done

    /// Marks the item at the given 1-based index as completed.
    ///
    /// - Parameter index: 1-based position in the item list.
    /// - Returns: Confirmation string, or an error if the index is out of range.
    @MainActor
    public static func done(index: Int) -> String {
        var itemsState = Application.fileState(\.items)
        var items = itemsState.value ?? []
        let zeroIndex = index - 1

        guard items.indices.contains(zeroIndex) else {
            return "Error: no task at index \(index). Use `list` to see valid indices."
        }

        guard !items[zeroIndex].isCompleted else {
            return "Task \(index) is already done: \(items[zeroIndex].title)"
        }

        items[zeroIndex].isCompleted = true
        itemsState.value = items

        // Clear in-memory selection if it pointed at this item.
        var selectionState = Application.state(\.selectedItemIndex)
        if selectionState.value == index {
            selectionState.value = nil
        }

        return "Done: \(items[zeroIndex].title)"
    }

    // MARK: - select

    /// Sets the in-memory "selected" item index for the current session.
    ///
    /// - Parameter index: 1-based position, or `nil` to deselect.
    /// - Returns: Confirmation string.
    @MainActor
    public static func select(index: Int?) -> String {
        let items = Application.fileState(\.items).value ?? []
        var selectionState = Application.state(\.selectedItemIndex)

        if let index {
            guard items.indices.contains(index - 1) else {
                return "Error: no task at index \(index)."
            }
            selectionState.value = index
            return "Selected task \(index): \(items[index - 1].title)"
        } else {
            selectionState.value = nil
            return "Selection cleared."
        }
    }

    // MARK: - clear

    /// Removes all items and resets the selected index.
    ///
    /// - Returns: Confirmation string.
    @MainActor
    public static func clear() -> String {
        var itemsState = Application.fileState(\.items)
        let count = (itemsState.value ?? []).count
        itemsState.value = []

        var selectionState = Application.state(\.selectedItemIndex)
        selectionState.value = nil

        return "Cleared \(count) task(s)."
    }

    // MARK: - stats

    /// Returns a summary line with session and lifetime counters.
    ///
    /// - Returns: Single-line summary string.
    @MainActor
    public static func stats() -> String {
        let current = Application.fileState(\.items).value ?? []
        let total = Application.storedState(\.totalItemsAdded).value
        let completed = current.filter(\.isCompleted).count
        let selectedValue = Application.state(\.selectedItemIndex).value
        let selected = selectedValue.map { "task \($0)" } ?? "none"
        return "Tasks: \(current.count) active, \(completed) completed, \(total) added all-time. Selected: \(selected)."
    }
}
