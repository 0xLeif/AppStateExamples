import AppState

// MARK: - Application State Extensions

extension Application {

    // MARK: In-Memory State

    /// A tap counter, incremented/reset via menu-bar buttons.
    /// The live value also appears in the menu-bar title label.
    internal var clickCount: State<Int> {
        state(initial: 0, id: "clickCount")
    }

    // MARK: UserDefaults-Backed State

    /// An editable greeting persisted across launches via `UserDefaults`.
    internal var greeting: StoredState<String> {
        storedState(initial: "Hello, AppState!", id: "greeting")
    }
}
