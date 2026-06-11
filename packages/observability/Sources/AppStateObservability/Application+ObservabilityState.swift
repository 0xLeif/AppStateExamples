import AppState
import Foundation

// MARK: - Models

/// A simple user profile used to demonstrate slice observation.
public struct UserProfile: Codable, Sendable, Equatable {
    /// The user's display name.
    public var displayName: String

    /// The user's score in some activity.
    public var score: Int

    /// Creates a new `UserProfile`.
    /// - Parameters:
    ///   - displayName: The display name.
    ///   - score: The initial score.
    public init(displayName: String, score: Int) {
        self.displayName = displayName
        self.score = score
    }
}

// MARK: - Application State Definitions

extension Application {

    // MARK: In-Memory State

    /// A simple incrementing counter — the canonical example for headless observation.
    public var counter: State<Int> {
        state(initial: 0, id: "obs.counter")
    }

    /// A temperature reading in degrees Celsius.
    public var temperature: State<Double> {
        state(initial: 20.0, id: "obs.temperature")
    }

    /// A boolean flag demonstrating that unrelated state mutations do not fire
    /// observers registered against a different state.
    public var unrelatedFlag: State<Bool> {
        state(initial: false, id: "obs.unrelatedFlag")
    }

    // MARK: Persisted State (UserDefaults)

    /// The last known event label, persisted across sessions via UserDefaults.
    /// Demonstrates that `StoredState` participates in Observation just like `State`.
    public var lastEvent: StoredState<String> {
        storedState(initial: "none", id: "obs.lastEvent")
    }

    // MARK: File-Backed State

    /// A running log of observation events, persisted to disk via `FileState`.
    /// Demonstrates that file-backed state also drives `withObservationTracking`.
    ///
    /// `@MainActor` is required because the `fileState(filename:)` factory on
    /// `Application` is itself `@MainActor`-isolated.
    @MainActor
    public var observationLog: FileState<[String]?> {
        fileState(filename: "observation_log.json")
    }

    // MARK: Structured State for Slices

    /// A user profile whose sub-properties can be observed individually via slices.
    public var userProfile: State<UserProfile> {
        state(initial: UserProfile(displayName: "Anonymous", score: 0), id: "obs.userProfile")
    }
}

// MARK: - Mutation Helpers

/// Convenience namespace for mutating `Application` state via the static API.
///
/// Swift 6 requires a `var` binding to call the mutating `State.value` setter
/// because `Application.state(_:)` returns a value type. These helpers wrap that
/// pattern behind a clean API so demo and test code stays readable.
public enum AppStateMutation {

    /// Sets `Application.counter` to the given value.
    /// - Parameter value: The new counter value.
    @MainActor
    public static func setCounter(_ value: Int) {
        var state = Application.state(\.counter)
        state.value = value
    }

    /// Sets `Application.temperature` to the given value.
    /// - Parameter value: The new temperature in degrees Celsius.
    @MainActor
    public static func setTemperature(_ value: Double) {
        var state = Application.state(\.temperature)
        state.value = value
    }

    /// Sets `Application.unrelatedFlag` to the given value.
    /// - Parameter value: The new flag value.
    @MainActor
    public static func setUnrelatedFlag(_ value: Bool) {
        var state = Application.state(\.unrelatedFlag)
        state.value = value
    }

    /// Sets `Application.lastEvent` to the given label string.
    /// - Parameter label: The new event label.
    @MainActor
    public static func setLastEvent(_ label: String) {
        var state = Application.storedState(\.lastEvent)
        state.value = label
    }

    /// Sets `Application.observationLog` to the given entries array (or `nil`).
    /// - Parameter entries: The new log entries, or `nil` to clear.
    @MainActor
    public static func setObservationLog(_ entries: [String]?) {
        var state = Application.fileState(\.observationLog)
        state.value = entries
    }

    /// Sets `Application.userProfile` to the given profile.
    /// - Parameter profile: The new `UserProfile` value.
    @MainActor
    public static func setUserProfile(_ profile: UserProfile) {
        var state = Application.state(\.userProfile)
        state.value = profile
    }

    /// Manually triggers the Observation anchor without changing a value.
    ///
    /// This demonstrates that any state write — even writing the same value back —
    /// travels through `notifyChange()` and wakes all active observers. This is
    /// useful when an external event (network push, file watcher) updates something
    /// outside AppState's own setters and you need to broadcast the change.
    @MainActor
    public static func broadcastChange() {
        var counterState = Application.state(\.counter)
        let current = counterState.value
        counterState.value = current   // same value write → notifyChange() fires
    }
}
