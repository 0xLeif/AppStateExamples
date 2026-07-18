import AppState
import Foundation
import Security

// MARK: - Application iCloud Sync Fallback

extension Application {

    // MARK: Entitlement Detection

    /// Whether the running process holds the `com.apple.developer.ubiquity-kvstore-identifier`
    /// entitlement required to touch `NSUbiquitousKeyValueStore`.
    ///
    /// Locally or ad-hoc signed builds never hold it, and reading the default store without
    /// it aborts the process (`BUG IN CLIENT OF KVS`).
    internal static var hasUbiquityKVStoreEntitlement: Bool {
        guard let task = SecTaskCreateFromSelf(nil) else { return false }
        return SecTaskCopyValueForEntitlement(
            task,
            "com.apple.developer.ubiquity-kvstore-identifier" as CFString,
            nil
        ) != nil
    }

    // MARK: Local Fallback Override

    /// Installs a local stand-in for AppState's `icloudStore` dependency when the iCloud KV
    /// entitlement is missing, so `SyncState` falls back to its local `StoredState`
    /// persistence instead of crashing the process at first access.
    ///
    /// Call once at launch — before any `SyncState` is resolved — and retain the returned
    /// token for the lifetime of the process. Returns `nil`, installing nothing, when real
    /// iCloud KV is available.
    @MainActor
    @discardableResult
    internal static func useLocalSyncStoreIfNeeded() -> Application.DependencyOverride? {
        guard !hasUbiquityKVStoreEntitlement else { return nil }
        return Application.override(\.icloudStore, with: LocalUbiquitousKeyValueStore())
    }
}

// MARK: - Local Ubiquitous Key-Value Store

/// A stateless `UbiquitousKeyValueStoreManaging` used when the iCloud KV entitlement is absent.
/// Reads always miss and writes are dropped, so `SyncState` serves its local `StoredState`
/// fallback (persisted via `UserDefaults`) — the documented degraded behavior.
internal struct LocalUbiquitousKeyValueStore: UbiquitousKeyValueStoreManaging {

    internal func data(forKey key: String) -> Data? {
        nil
    }

    internal func set(_ value: Data?, forKey key: String) {}

    internal func removeObject(forKey key: String) {}
}
