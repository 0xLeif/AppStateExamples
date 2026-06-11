# SwiftUIDemo — AppState 3.0 Catalog App

A SwiftUI catalog app (iOS 17 + macOS 14) that tours the full breadth of **AppState 3.0**.  
Every state type, dependency pattern, slice, SwiftData integration, and the headline headless-observation feature is demonstrated in a real, navigable UI.

---

## Getting started

### Prerequisites

- Xcode 15 or later
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Generate and open the project

```bash
cd apps/SwiftUIDemo
xcodegen generate
open SwiftUIDemo.xcodeproj
```

### Schemes

| Scheme | Purpose |
|--------|---------|
| `SwiftUIDemo-iOS` | Run / archive the iOS target; test action runs `SwiftUIDemoUITests_iOS` |
| `SwiftUIDemo-macOS` | Run / archive the macOS target; test action runs `SwiftUIDemoUITests_macOS` |

> xcodegen splits the multiplatform target into `SwiftUIDemo_iOS` and `SwiftUIDemo_macOS`.
> Select **SwiftUIDemo-iOS** with an iOS simulator, or **SwiftUIDemo-macOS** → **My Mac** to run.

---

## What each section demonstrates

### State tab

| Screen | Wrapper | Backing store |
|--------|---------|---------------|
| Counter | `@AppState` | In-memory (resets on quit) |
| Username | `@StoredState` | `UserDefaults` (persists across launches) |
| Profile Editor | `@FileState` | JSON file in the app sandbox |

### Secure & Sync tab

| Screen | Wrapper | Backing store |
|--------|---------|---------------|
| API Token | `@SecureState` | System Keychain |
| Theme Toggle | `@SyncState` | `NSUbiquitousKeyValueStore` (iCloud KV) |

> Both require device entitlements. Keychain works on physical devices and signed simulator builds. iCloud sync requires an iCloud-enabled container entitlement configured in Xcode.

### Dependencies tab

| Screen | Pattern | What it shows |
|--------|---------|---------------|
| Greeting Service | `@AppDependency` + `Application.override` | Hot-swapping a `GreetingProviding` protocol implementation at runtime; same mechanism used in unit tests |
| Observable Counter | `@ObservedDependency` | An `ObservableObject` service whose `@Published` ticks re-render the view |

### Slices tab

`ProfileSliceView` shows:
- `@Slice(\.userSettings, \.fontSize)` — targeting a non-optional `State<UserSettings>` field
- `@Slice(\.userSettings, \.notificationsEnabled)` — another independent field slice
- `@OptionalSlice(\.profile, \.displayName)` — targeting a field inside `FileState<Profile?>`, returning `nil` gracefully when no profile has been saved

### SwiftData tab

`TodoListView` demonstrates:
- `.modelContainer(Application.dependency(\.container))` wired in the `App` scene
- `@Query` for reactive SwiftUI list updates (SwiftData native)
- `$todos.insert(_:)` — lenient insert (logs & swallows errors)
- `$todos.delete(_:)` — lenient delete
- `$todos.strict.insert(_:)` inside a `do/catch` — surfaces errors in an `Alert`
- `$todos.deleteAll()` — bulk delete

### Observability tab

`ObservabilitySection` + `HeadlessObserver` prove AppState 3.0's headline feature:

- `HeadlessObserver` is a plain `final class` — no SwiftUI, no `@Observable` macro, no `ObservableObject`
- It uses `withObservationTracking` to subscribe to `Application.counter` changes
- On each change the `onChange` closure fires, appends a timestamped log entry, and **re-arms itself** for continuous observation
- The same `Application.counter` is also mutated by the Stepper in the Observability tab and by the Counter screen in the State tab — both drive the headless log

---

## Project structure

```
apps/SwiftUIDemo/
├── project.yml                          # XcodeGen spec
├── Sources/
│   ├── App/
│   │   ├── SwiftUIDemoApp.swift         # @main entry, .modelContainer scene modifier
│   │   ├── RootCatalogView.swift        # TabView catalog root
│   │   └── Info.plist
│   ├── Application/                     # Application extension definitions
│   │   ├── Application+State.swift
│   │   ├── Application+SecureSync.swift
│   │   ├── Application+Dependencies.swift
│   │   ├── Application+Slices.swift
│   │   └── Application+SwiftData.swift
│   ├── Models/                          # Value types, services, SwiftData model
│   │   ├── Profile.swift
│   │   ├── UserSettings.swift
│   │   ├── GreetingService.swift
│   │   ├── LiveCounterService.swift
│   │   └── TodoItem.swift
│   └── Views/
│       ├── State/
│       │   ├── StateSection.swift
│       │   ├── CounterView.swift
│       │   ├── UsernameView.swift
│       │   └── ProfileEditorView.swift
│       ├── SecureSync/
│       │   ├── SecureSyncSection.swift
│       │   ├── SecureTokenView.swift
│       │   └── ThemeToggleView.swift
│       ├── Dependencies/
│       │   ├── DependenciesSection.swift
│       │   ├── GreetingView.swift
│       │   └── ObservedCounterView.swift
│       ├── Slices/
│       │   ├── SlicesSection.swift
│       │   └── ProfileSliceView.swift
│       ├── SwiftData/
│       │   ├── SwiftDataSection.swift
│       │   └── TodoListView.swift
│       └── Observability/
│           ├── HeadlessObserver.swift
│           └── ObservabilitySection.swift
└── UITests/
    ├── TodoListUITests.swift
    └── ObservabilityUITests.swift
```
