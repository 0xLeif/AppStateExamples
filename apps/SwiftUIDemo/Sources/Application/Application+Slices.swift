import AppState

// MARK: - Sliced State Extensions

extension Application {

    // MARK: UserSettings State (for @Slice demo)

    /// Composite settings struct — individual fields are accessed via `@Slice`.
    internal var userSettings: State<UserSettings> {
        state(initial: UserSettings(), id: "userSettings")
    }
}
