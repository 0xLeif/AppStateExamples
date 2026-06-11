# AppState 3.0 — API Brief for Example Authors

This is the authoritative cheat sheet for writing AppState 3.0.0 examples. **Do not invent API beyond this.** If unsure, keep it simple and use only what's listed here.

Pin the dependency exactly:
```swift
.package(url: "https://github.com/0xLeif/AppState.git", exact: "3.0.0-rc.1")
```
`import AppState` to use it.

## Platform availability (CRITICAL)

| Feature | Linux | WASM | Apple (iOS/macOS/tvOS/watchOS/visionOS) |
| --- | --- | --- | --- |
| `State`, `@AppState` | ✅ | ✅ | ✅ |
| `StoredState`, `@StoredState` (UserDefaults) | ✅ | ⚠️ avoid on WASM | ✅ |
| `FileState`, `@FileState` | ✅ | ⚠️ avoid on WASM | ✅ |
| `Dependency`, `@AppDependency`, `@ObservedDependency` | ✅ | ✅ | ✅ |
| `@Slice` / `@OptionalSlice` / `@DependencySlice` | ✅ | ✅ | ✅ |
| Headless observation (`withObservationTracking`) | ✅ | ✅ | ✅ |
| `SyncState` (NSUbiquitousKeyValueStore) | ❌ | ❌ | ✅ |
| `SecureState` (Keychain) | ❌ | ❌ | ✅ |
| `ModelState` / `@ModelState` (SwiftData) | ❌ | ❌ | ✅ (`#if canImport(SwiftData)`) |
| SwiftUI (`@AppState` in views, `Binding`) | ❌ | ❌ | ✅ |

Guard Apple-only code with `#if canImport(SwiftData)`, `#if canImport(SwiftUI)`, or `#if !os(Linux) && !os(Windows)` as appropriate.

## Defining state & dependencies (extend `Application`)

```swift
import AppState

extension Application {
    // Plain in-memory state
    var counter: State<Int> { state(initial: 0, id: "counter") }

    // UserDefaults-backed (NOT on WASM)
    var username: StoredState<String> { storedState(initial: "", id: "username") }

    // File-backed Codable (NOT on WASM)
    var profile: FileState<Profile?> { fileState(filename: "profile") }

    // Dependency injection
    var clock: Dependency<any Clocking> { dependency(SystemClock(), id: "clock") }

    // Apple-only: iCloud KV sync
    var theme: SyncState<String> { syncState(initial: "light", id: "theme") }

    // Apple-only: Keychain
    var apiToken: SecureState { secureState(id: "apiToken") }
}
```

Factory signatures (instance methods on `Application`):
- `state(initial: Value, feature: String = "App", id: String) -> State<Value>` (also an `id`-less overload using call-site)
- `storedState(initial: Value, feature: String = "App", id: String) -> StoredState<Value>`; `storedState(feature:id:) -> StoredState<Value?>`
- `fileState(initial: Value, path: String = ..., filename: String, isBase64Encoded: Bool = true) -> FileState<Value>`; `fileState(filename:) -> FileState<Value?>`
- `dependency(_ object: Value, feature: String = "App", id: String) -> Dependency<Value>`
- `syncState(initial: Value, feature: String = "App", id: String) -> SyncState<Value>` (Apple-only)
- `secureState(initial: String? = nil, feature: String = "App", id: String) -> SecureState` (Apple-only)
- `modelState(container: KeyPath<Application, Dependency<ModelContainer>>, ...) -> ModelState<Model>` (SwiftData)
- `modelContainer(_ container: ModelContainer, ...) -> Dependency<ModelContainer>` (SwiftData)

## Property wrappers (use inside views / view models / services)

```swift
@AppState(\.counter) var counter: Int          // read & write
@StoredState(\.username) var username: String
@FileState(\.profile) var profile: Profile?
@AppDependency(\.clock) var clock: any Clocking
@ObservedDependency(\.observableService) var service  // dependency conforms to ObservableObject
@ModelState(\.items) var items                  // SwiftData; $items.insert(_:)/delete(_:)/save()/deleteAll()
```

## Static access (no property wrapper needed — great for CLI/server/headless)

```swift
let value = Application.state(\.counter).value         // read (registers observation)
Application.state(\.counter).value = 5                 // write (must be on main thread)
let clock = Application.dependency(\.clock)            // resolve a dependency
Application.logging(isEnabled: true)
let token = Application.override(\.clock, with: MockClock()); token.cancel()  // testing
```

## NEW IN 3.0 — Observation without SwiftUI (the headline feature)

`Application` is now `@Observable` (was `ObservableObject`). Reading `Application.state(_:).value` participates in Observation, so **any** code can react to changes via `withObservationTracking` — no SwiftUI required:

```swift
import Observation

func observeCounter() {
    withObservationTracking {
        _ = Application.state(\.counter).value
    } onChange: {
        // Fires once, synchronously, on the NEXT change. Re-arm to keep observing.
        print("counter changed")
        observeCounter()   // re-arm for continuous observation
    }
}
```

`onChange` is one-shot — re-call your tracking function inside `onChange` to keep listening. Mutations must happen on the main thread (`Application.notifyChange()` asserts main-thread).

## SwiftData (`ModelState`) — Apple only

```swift
@Model final class TodoItem { var title: String; init(title: String) { self.title = title } }

extension Application {
    var container: Dependency<ModelContainer> {
        modelContainer(try! ModelContainer(for: TodoItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    }
    var todos: ModelState<TodoItem> { modelState(container: \.container) }
}

// Read & mutate
let todos = Application.modelState(\.todos)
todos.insert(TodoItem(title: "Ship 3.0"))   // lenient: logs & swallows errors
try todos.strict.insert(TodoItem(title: "Tag rc")) // strict: throws on failure
let all = todos.models                        // live fetch
```

## CorvidLabs / 0xLeif conventions (MANDATORY)

1. Explicit access control on EVERY declaration (`public`/`internal`/`private`).
2. K&R braces — opening brace on the same line.
3. NO force unwrap (`!`), `try!`, or `as!` in example library code. (`try!` is tolerable ONLY in a `ModelContainer` initializer in a demo, matching the repo's own examples — but prefer `do/catch`.)
4. async/await only — no completion handlers.
5. `Sendable` conformance for types crossing concurrency boundaries; `@Sendable` closures where needed.
6. Descriptive generics (`Value`, `Output`, `Key`) — never single letters.
7. 4-space indent, 120-col lines, doc comments on public API.
8. `swift-tools-version: 6.0`, `swiftLanguageModes: [.v6]`, and `swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]`.

## What to SHOW OFF

Every example should make these tangible:
- **Observability without SwiftUI** (`withObservationTracking`, re-arming, multiple observers).
- The breadth of state types appropriate to the platform.
- Dependency injection + test overrides.
- That mutations are thread-safe / main-thread-driven.
