# AppState 3.0 — Observability Without SwiftUI

The headline feature of AppState 3.0 is that `Application` is now `@Observable` (previously `ObservableObject`). This means **any** Swift code — CLI tools, server-side processes, background actors, plain classes — can react to state changes via `withObservationTracking`, with no SwiftUI required.

## 2.x → 3.0 at a Glance

| | AppState 2.x | AppState 3.0 |
|---|---|---|
| Observation protocol | `ObservableObject` | `@Observable` |
| Observation trigger | `objectWillChange.sink` | `withObservationTracking` |
| Requires SwiftUI? | Yes (for `@Published` views) | No |
| Works in CLI / server? | No | Yes |
| Works on Linux? | No | Yes |

## What This Package Demonstrates

### 1. Basic Headless Observation (`StateObserver`)

`withObservationTracking` fires its `onChange` closure exactly once. To keep observing, you must re-arm inside `onChange`. The `StateObserver` class encapsulates this pattern:

```swift
let observer = StateObserver(label: "counter") {
    Application.state(\.counter).value
}
observer.start()
Application.state(\.counter).value = 1  // fires observer
Application.state(\.counter).value = 2  // fires again (re-armed)
observer.stop()
```

### 2. One-shot Observation (`observeOnce`)

When you need a single wake-up call on the next mutation:

```swift
observeOnce({ Application.state(\.counter).value }) { newValue in
    print("counter became \(newValue)")
}
```

### 3. Multiple Independent Observers

All N observers registered against the same state fire on a single mutation — a broadcast, not a unicast:

```swift
for i in 1...5 {
    withObservationTracking {
        _ = Application.state(\.counter).value
    } onChange: {
        print("observer \(i) fired")
    }
}
Application.state(\.counter).value = 1  // all 5 fire
```

### 4. Observing Across State Types

`State`, `StoredState`, and `FileState` all route through the same `@Observable` anchor:

```swift
// In-memory state
withObservationTracking { _ = Application.state(\.temperature).value } onChange: { ... }

// UserDefaults-backed
withObservationTracking { _ = Application.storedState(\.lastEvent).value } onChange: { ... }

// File-backed
withObservationTracking { _ = Application.fileState(\.observationLog).value } onChange: { ... }
```

### 5. Slice Observation

Observe just one property of a structured state value:

```swift
withObservationTracking {
    _ = Application.slice(\.userProfile, \.score).value
} onChange: {
    print("score changed to \(Application.slice(\.userProfile, \.score).value)")
}
```

### 6. Manual `notifyChange()`

For external-change scenarios (incoming iCloud data, WebSocket pushes), call `notifyChange()` directly to broadcast to all active observers:

```swift
Application.shared.notifyChange()  // wakes every observer registered on any state
```

### 7. AsyncStream Bridge (`ObservationStream`)

Converts the callback-oriented `withObservationTracking` API into an idiomatic Swift concurrency stream:

```swift
let stream = ObservationStream.make(label: "counter") {
    Application.state(\.counter).value
}

for await value in stream {
    print("counter is now \(value)")
}
```

The first element is always an immediate snapshot of the current value. The stream terminates cleanly when the consuming `Task` is cancelled.

## Running

```bash
# Build
swift build

# Run the narrated demo
swift run observability-demo

# Run tests
swift test
```

## Platform Notes

This package targets macOS 14+ and Linux. It deliberately avoids SwiftUI, SwiftData, Keychain (`SecureState`), and iCloud (`SyncState`) — all of which are Apple-only — to demonstrate that the core observability story works everywhere.
