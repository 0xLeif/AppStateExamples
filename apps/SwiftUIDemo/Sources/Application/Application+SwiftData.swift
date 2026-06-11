#if canImport(SwiftData)
import AppState
import SwiftData

// MARK: - Application SwiftData Extensions

extension Application {

    // MARK: ModelContainer Dependency

    /// The shared `ModelContainer` for this app's SwiftData schema.
    ///
    /// Defined as an `Application` instance property using the `modelContainer(_:)` factory,
    /// which registers the container as a dependency with an automatically-generated identifier.
    /// The container is evaluated lazily — only when first accessed.
    internal var container: Dependency<ModelContainer> {
        modelContainer(makeModelContainer())
    }

    // MARK: ModelState

    /// The live list of `TodoItem` models backed by the shared container.
    ///
    /// - Note: `ModelState` mutations are not automatically broadcast to SwiftUI.
    ///   Use SwiftData's `@Query` in views for reactivity; reach for `$todos.insert(_:)` etc.
    ///   from non-view code or when an explicit mutation with error handling is needed.
    internal var todos: ModelState<TodoItem> {
        modelState(container: \.container)
    }
}

// MARK: - Private Helpers

/// Creates the `ModelContainer` for the app's SwiftData schema.
///
/// Prefers a persistent on-disk store; falls back to in-memory if the persistent
/// store cannot be created, surfacing the error via `ApplicationLogger` rather
/// than crashing with `fatalError`.
private func makeModelContainer() -> ModelContainer {
    do {
        return try ModelContainer(for: TodoItem.self)
    } catch {
        // Log the degradation. In production code you would surface this through your
        // own logging infrastructure; for this demo a print is sufficient.
        print("[SwiftUIDemo] Persistent ModelContainer unavailable (\(error)). Using in-memory store.")
        // The in-memory fallback should never fail; treat failure here as a fatal
        // configuration error — there is nothing meaningful to recover from.
        return try! ModelContainer(
            for: TodoItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
#endif
