# Pomodoro — AppState 3.0 Example

A fully functional Pomodoro timer for iOS and macOS, built to show how AppState 3.0
pieces fit together in a real, cohesive architecture — not a feature catalog.

## What it demonstrates

| AppState concept | Where it appears |
|---|---|
| `State<T>` (in-memory) | `phase`, `remainingSeconds`, `isRunning` — live timer that resets on launch |
| `StoredState<T>` (UserDefaults) | `workMinutes`, `breakMinutes`, `completedSessions` — persisted settings and progress |
| `Dependency<any Ticker>` | Injects a `LiveTicker` (real `Task.sleep` loop); swap for tests via `Application.override` |
| `@AppState` property wrapper | Every view observes state reactively — no manual `objectWillChange` needed |
| Mutations via `var s = Application.state(\.x); s.value = y` | `PomodoroEngine` is the single place state changes, keeping the pattern explicit |

## Architecture

```
Sources/
├── App/
│   ├── PomodoroApp.swift         @main entry point
│   └── Info.plist
├── Application/
│   ├── Application+PomodoroState.swift      State + StoredState definitions
│   └── Application+PomorodoDependency.swift  Ticker dependency
├── Models/
│   ├── Phase.swift               Sendable enum — work / shortBreak / longBreak
│   └── Ticker.swift              Ticker protocol + LiveTicker + TickerToken
├── Engine/
│   └── PomodoroEngine.swift      @MainActor controller; the ONLY place state mutates
└── Views/
    ├── TimerScreenView.swift     Main screen — ring + label + controls
    ├── SettingsView.swift        Steppers bound directly to $workMinutes/$breakMinutes
    ├── TimerRingView.swift       Circular progress ring, color-coded by phase
    ├── TimerDisplayView.swift    MM:SS label with numeric transition
    ├── ControlButtonsView.swift  Start/Pause + Reset buttons
    └── SessionBadgeView.swift    Completed-session count badge
```

### How the pieces fit

1. **State is declared once** in `Application` extensions. Every declaration is a
   computed property returning a typed container — AppState 3.0's factory pattern.

2. **Views only read** via `@AppState(\.x)`. SwiftUI re-renders automatically
   because `Application` is `@Observable` in 3.0. No `ObservableObject`, no
   `@Published`, no manual notification.

3. **`PomodoroEngine` owns all writes.** It calls
   `var s = Application.state(\.phase); s.value = .shortBreak` — the two-step
   pattern required because assignment to a function-call result is not valid Swift.

4. **The `Ticker` dependency** isolates real time from the engine. Tests or
   Xcode Previews can call `Application.override(\.ticker, with: MockTicker())`
   to drive the engine at any speed without real `Task.sleep`.

5. **`StoredState` is zero-ceremony persistence.** `workMinutes`, `breakMinutes`,
   and `completedSessions` are just `@AppState`-observed in `SettingsView` — the
   `$binding` writes straight to UserDefaults.

## How to build and run

### Prerequisites

- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Generate the project

```bash
cd apps/Pomodoro
xcodegen generate
```

### Run in Xcode

Open `Pomodoro.xcodeproj`, select the `Pomodoro-iOS` or `Pomodoro-macOS` scheme,
and press Run.

### Build from the command line

```bash
# macOS
xcodebuild build \
  -project Pomodoro.xcodeproj \
  -scheme "Pomodoro-macOS" \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO

# iOS Simulator
xcodebuild build \
  -project Pomodoro.xcodeproj \
  -scheme "Pomodoro-iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO
```

## Testing with a mock ticker

```swift
// In an XCTest:
func testAdvancesPhaseAtZero() async throws {
    let override = Application.override(\.ticker, with: InstantTicker())
    defer { Task { @MainActor in await override.cancel() } }

    // seed state
    var remaining = Application.state(\.remainingSeconds)
    remaining.value = 1

    await PomodoroEngine.shared.tick() // drives to zero → advancePhase()

    let phase = Application.state(\.phase).value
    XCTAssertEqual(phase, .shortBreak)
}
```

## Verification

From the repository root, `fledge run test-apple-apps` runs seven engine behavior tests and six image-regression
snapshots covering idle/running focus, short and long breaks, settings, and reusable components. The latest full run
covered 96.00% of `Pomodoro.app`; CI enforces a 95% minimum.
