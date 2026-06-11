# vapor-example

Server-side Swift (Vapor 4) demonstrating AppState 3.0 as a dependency-injection
container and observable-state store — with zero SwiftUI, Keychain, SwiftData, or
iCloud dependencies, running on macOS and Linux.

## What this shows

| AppState feature | Where |
|---|---|
| `State<T>` — in-process config & metrics counter | `Application+VaporState.swift` |
| `StoredState<T>` — UserDefaults-backed greeting template | `Application+VaporState.swift` |
| `Dependency<any GreetingService>` — injected service | `Application+VaporState.swift`, `GreetingService.swift` |
| `Dependency<RequestMetrics>` — injected actor | `Application+VaporState.swift`, `RequestMetrics.swift` |
| `withObservationTracking` headless observer | `MetricsObserver.swift` |
| Main-thread mutation pattern | `Routes.swift` |
| `Application.override` in tests | `AppStateVaporCoreTests.swift` |

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Health check — returns `appName` from `State` + total request count |
| `GET` | `/greet/:name` | Personalized greeting via injected `GreetingService` + `StoredState` template |
| `GET` | `/metrics` | Snapshot of per-route hits (actor) and total count (State) |
| `POST` | `/config` | Mutates `appName` and/or `greetingTemplate` at runtime |

### POST /config body (JSON)

```json
{
  "appName": "My Server",
  "greetingTemplate": "Hey {name}, welcome to {appName}!"
}
```

Both fields are optional — omit either to leave it unchanged.

## Running

Runs locally on macOS and Linux. The server defaults to `http://127.0.0.1:8080`; pass
`--port` if that's taken (e.g. by a local `algod`, which also uses 8080):

```bash
cd packages/vapor-example
swift run vapor-example serve --hostname 127.0.0.1 --port 8099
```

> **Note on directory naming**: the package directory is `vapor-example/` (not `vapor/`).
> SwiftPM derives the package identity from the directory name when the package is
> nested inside a git repository.  Using `vapor/` would create an identity collision
> with the `vapor` dependency package and cause dependency resolution to silently fail.

### Smoke test

With the server running on `:8099`:

```bash
curl http://127.0.0.1:8099/
# {"appName":"AppState Vapor Example","totalRequests":1,"status":"ok"}

curl http://127.0.0.1:8099/greet/Leif
# {"greeting":"Hello, Leif! Welcome to AppState Vapor Example."}

# Mutate the StoredState greeting template (hops to the main actor server-side)
curl -X POST http://127.0.0.1:8099/config \
  -H "Content-Type: application/json" \
  -d '{"greetingTemplate":"Yo, {name}! 👋"}'

curl http://127.0.0.1:8099/greet/Leif
# {"greeting":"Yo, Leif! 👋"}   <- the config change is reflected

curl http://127.0.0.1:8099/metrics
# {"totalRequests":7,"routeCounts":{"GET /":2,"GET /greet/:name":3,"POST /config":1,"GET /metrics":2}}
```

Verified end-to-end on macOS: `State` (app name / request counter), `StoredState`
(greeting template), the injected `GreetingService`, and the `RequestMetrics` actor all
work in a live server.

## Running tests

```bash
swift test
```

## The main-thread mutation lesson

AppState's `Application` is `@Observable`.  Every state write calls
`Application.notifyChange()`, which asserts `Thread.isMainThread`.

Vapor route handlers run on NIO **EventLoop** threads — not the main thread.
Reading AppState state from a handler is fine; the internal lock keeps reads
thread-safe.  But **any write must be dispatched to the main actor**:

```swift
// CORRECT — hop to MainActor before mutating State.
// `Application.state(_:)` returns a value-type State<T> copy; bind to `var`
// so Swift accepts the `.value = …` mutation syntax.  The setter's side-effect
// writes to Application.shared.cache, so the change is durable.
await MainActor.run {
    var counter = Application.state(\.totalRequestCount)
    counter.value += 1
    var nameState = Application.state(\.appName)
    nameState.value = newName
}

// WRONG — will trigger a runtime assertion failure in debug builds
Application.state(\.totalRequestCount).value += 1  // NOT on main thread!
```

Also note that `Application.dependency(_:)` is `@MainActor`, so dependency
resolution also requires a main-thread hop:

```swift
// CORRECT
let service = await MainActor.run { Application.dependency(\.greetingService) }

// WRONG — compiler error in strict concurrency
let service = Application.dependency(\.greetingService) // @MainActor isolation violation
```

For values you only need to **count or accumulate** concurrently — without
feeding SwiftUI or `withObservationTracking` — prefer an `actor` like
`RequestMetrics`.  The actor is safe from any concurrency context and does not
require a main-thread hop.

Both patterns live side-by-side in `Routes.swift` so you can compare them directly.
