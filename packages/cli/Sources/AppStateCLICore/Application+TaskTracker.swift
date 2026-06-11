import AppState
import Foundation

// MARK: - Application Extension

extension Application {

    // MARK: In-Memory State

    /// The 1-based index of the currently "selected" item for interactive use.
    /// `nil` means no item is selected.
    public var selectedItemIndex: State<Int?> {
        state(initial: nil, id: "selectedItemIndex")
    }

    // MARK: Persisted State (UserDefaults)

    /// Running total of items ever added across sessions.
    public var totalItemsAdded: StoredState<Int> {
        storedState(initial: 0, id: "totalItemsAdded")
    }

    // MARK: File-Backed State

    /// The persisted item list. `nil` means no file has been written yet.
    ///
    /// Marked `@MainActor` because `fileState(filename:)` is main-actor isolated.
    @MainActor
    public var items: FileState<[TodoItem]?> {
        fileState(filename: "items.json")
    }

    // MARK: Dependencies

    /// Injected ID generator — swap in tests via `Application.override`.
    public var idGenerator: Dependency<any IDGenerating> {
        dependency(UUIDGenerator(), id: "idGenerator")
    }

    /// Injected clock — swap in tests via `Application.override`.
    public var clock: Dependency<any Clocking> {
        dependency(SystemClock(), id: "clock")
    }
}
