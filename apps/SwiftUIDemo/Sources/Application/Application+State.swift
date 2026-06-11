import AppState

// MARK: - Application State Extensions

extension Application {

    // MARK: In-Memory State

    /// A simple integer counter, incremented/decremented with a Stepper.
    internal var counter: State<Int> {
        state(initial: 0, id: "counter")
    }

    // MARK: UserDefaults-Backed State

    /// The user's chosen display username, persisted across launches.
    internal var username: StoredState<String> {
        storedState(initial: "", id: "username")
    }

    // MARK: File-Backed State

    /// A `Codable` user profile persisted to the app-sandbox file system.
    @MainActor
    internal var profile: FileState<Profile?> {
        fileState(filename: "profile.json")
    }
}
