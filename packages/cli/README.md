# appstate-cli

A small task-tracker CLI that demonstrates every core AppState 3.0 feature
on **macOS and Linux** (no SwiftUI, no SwiftData, no Keychain, no SyncState).

## What it shows

| AppState feature | Where used |
|---|---|
| `State<Int?>` | In-memory selected-task index (session only) |
| `StoredState<Int>` | Lifetime task counter in UserDefaults |
| `FileState<[Task]?>` | Persisted task list on disk (Codable) |
| `Dependency<any IDGenerating>` | Injected UUID factory |
| `Dependency<any Clocking>` | Injected clock for testable timestamps |
| `Application.override` | Test-time dependency substitution |
| `withObservationTracking` (re-armed) | Headless observation without SwiftUI |

## Running

```sh
cd packages/cli
swift run appstate-cli help
swift run appstate-cli add "Write more tests"
swift run appstate-cli add "Ship 3.0"
swift run appstate-cli list
swift run appstate-cli done 1
swift run appstate-cli stats
swift run appstate-cli watch      # headless observation demo
swift run appstate-cli clear
```

## Testing

```sh
swift test
```

## Platform support

Runs on **macOS 14+** and **Linux** (Ubuntu 22.04+, Debian 12+).
Only Foundation and AppState are imported — no Apple-specific frameworks.
