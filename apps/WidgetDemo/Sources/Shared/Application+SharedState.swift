import Foundation
import AppState

// MARK: - Application Shared State

extension Application {

    // MARK: Shared StoredState

    /// The user's current focus session title, stored in the shared App Group UserDefaults.
    /// Both the app and widget extension read and write this value.
    internal var focusTitle: StoredState<String> {
        storedState(initial: "Focus Session", id: "focusTitle")
    }

    /// The total number of completed focus increments, stored in the shared App Group UserDefaults.
    /// Both the app and widget extension read and display this value.
    internal var focusCount: StoredState<Int> {
        storedState(initial: 0, id: "focusCount")
    }

    // MARK: Shared Defaults Override

    /// Redirects AppState's `userDefaults` dependency to the App Group suite so that
    /// `StoredState` values are shared between the app process and the widget extension process.
    ///
    /// Call this once at launch in BOTH the app target and the widget extension target —
    /// before any `StoredState` is first accessed — so both processes resolve values from the
    /// same `UserDefaults` container.
    ///
    /// The returned `DependencyOverride` token lives for the lifetime of the process.
    /// Assigning it to a static property retains it forever without creating a retain cycle.
    @MainActor
    @discardableResult
    internal static func useSharedDefaults() -> Application.DependencyOverride? {
        let suiteName = "group.com.0xleif.AppStateWidgetDemo"
        guard UserDefaults(suiteName: suiteName) != nil else {
            return nil
        }
        let wrapper = AppGroupUserDefaults(suiteName: suiteName)
        return Application.override(\.userDefaults, with: wrapper)
    }
}

// MARK: - App Group UserDefaults Wrapper

/// Wraps an App Group `UserDefaults` suite name and conforms to `UserDefaultsManaging`
/// so it can be injected into AppState's `userDefaults` dependency.
///
/// `UserDefaults` itself is not `Sendable`, so only the suite name `String` is stored.
/// Each method resolves the suite via `UserDefaults(suiteName:)` and falls back to
/// `.standard` if the suite is unavailable at access time (e.g. before entitlements
/// are honoured in the simulator without a signing team).
internal struct AppGroupUserDefaults: UserDefaultsManaging {

    // MARK: Properties

    /// The App Group UserDefaults suite identifier.
    private let suiteName: String

    // MARK: Initializer

    /// Creates a wrapper for the given suite name.
    /// - Parameter suiteName: The App Group suite identifier.
    internal init(suiteName: String) {
        self.suiteName = suiteName
    }

    // MARK: Private Helpers

    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // MARK: UserDefaultsManaging

    internal func object(forKey key: String) -> Any? {
        defaults.object(forKey: key)
    }

    internal func removeObject(forKey key: String) {
        defaults.removeObject(forKey: key)
    }

    internal func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}
