# WidgetDemo

An iOS app + WidgetKit widget extension that share `StoredState` across the process boundary via an **App Group** and AppState 3.0.

## What This Demonstrates

- Sharing `StoredState` (UserDefaults-backed) between two separate processes — the app and a widget extension — using a single App Group suite.
- Overriding AppState's built-in `userDefaults` dependency at launch in **both** processes so every `StoredState` read/write goes to the shared container.
- Triggering widget timeline refreshes with `WidgetCenter.shared.reloadAllTimelines()` after each mutation.
- Swift 6 strict concurrency throughout, including a `UserDefaultsManaging`-conforming wrapper for the App Group suite.

---

## The App Group Sharing Pattern

`StoredState` is backed by AppState's injectable `userDefaults` dependency (type `any UserDefaultsManaging`). By default it uses `UserDefaults.standard`, which is **process-local** — the widget extension cannot see it.

To share values, both processes must point AppState at the same App Group `UserDefaults` suite. The mechanism is `Application.override(_:with:)`:

```swift
// Sources/Shared/Application+SharedState.swift
@MainActor
@discardableResult
internal static func useSharedDefaults() -> Application.DependencyOverride? {
    let suiteName = "group.com.0xleif.AppStateWidgetDemo"
    guard UserDefaults(suiteName: suiteName) != nil else { return nil }
    return Application.override(\.userDefaults, with: AppGroupUserDefaults(suiteName: suiteName))
}
```

`Application.override` returns an `Application.DependencyOverride` token. Releasing the token cancels the override, so we keep it alive for the full process lifetime by assigning it to a `static` property in the app/widget entry points:

```swift
// WidgetDemoApp.swift and FocusWidgetBundle.swift
private static let sharedDefaultsToken: Application.DependencyOverride? = {
    Application.useSharedDefaults()
}()
```

Both files call `_ = Self.sharedDefaultsToken` in their `@MainActor` initializers, which forces the lazy static to initialize on the main actor before any view or timeline provider runs.

### Why `AppGroupUserDefaults` Instead of Raw `UserDefaults`

`UserDefaults` is not `Sendable` in Swift 6. `UserDefaultsManaging` is `Sendable`. The wrapper stores only a `String` (the suite name) and resolves the `UserDefaults` suite on each call — the same pattern AppState's own `SendableUserDefaults` uses for `UserDefaults.standard`:

```swift
internal struct AppGroupUserDefaults: UserDefaultsManaging {
    private let suiteName: String
    private var defaults: UserDefaults { UserDefaults(suiteName: suiteName) ?? .standard }
    // ...
}
```

---

## File Layout

```
Sources/
  Shared/
    Application+SharedState.swift   # StoredState definitions + useSharedDefaults() + AppGroupUserDefaults
  App/
    WidgetDemoApp.swift             # @main app entry point
    FocusEditorView.swift           # Edit focusTitle, increment focusCount, reload widget
    Info.plist
  Widget/
    FocusWidgetBundle.swift         # @main widget entry point
    FocusWidget.swift               # StaticConfiguration (.systemSmall + .systemMedium)
    FocusTimelineProvider.swift     # Reads StoredState, emits FocusEntry
    FocusWidgetView.swift           # Widget UI
    FocusEntry.swift                # TimelineEntry
    Info.plist
SupportingFiles/
  WidgetDemo.entitlements           # com.apple.security.application-groups
  WidgetDemoWidget.entitlements     # com.apple.security.application-groups
project.yml                         # xcodegen spec
```

---

## Generate and Run

### Prerequisites

- Xcode 15+ (iOS 17 SDK)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A real signing team + App Group provisioning profile (required for the App Group to actually function on device/simulator)

### Generate the Xcode project

```bash
cd apps/WidgetDemo
xcodegen generate
```

### Open and run

```bash
open WidgetDemo.xcodeproj
```

Select the **WidgetDemo** scheme, choose a simulator or device, and run. To test the widget, add the "Focus Session" widget to the Home Screen from the widget gallery.

### Compile-check without signing

```bash
xcodebuild build \
  -project WidgetDemo.xcodeproj \
  -scheme WidgetDemo \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO
```

> **Note:** The App Group entitlement (`group.com.0xleif.AppStateWidgetDemo`) requires a real signing team and matching provisioning profile to be honoured at runtime. Without signing, the code compiles cleanly but `UserDefaults(suiteName:)` will fall back to `.standard`, meaning cross-process sharing will not work. This is expected for unsigned builds.

---

## How the AppState Override Mechanism Works

1. `Application.override(\.userDefaults, with: value)` replaces the registered dependency for the current process until the returned token is cancelled.
2. All `@StoredState` property wrappers and `Application.state(\.focusTitle)` static accesses resolve the dependency fresh on each read, so they see the overridden suite immediately.
3. Because the override is installed in **both** the app entry point and the widget bundle entry point — before any state is accessed — both processes share the same `UserDefaults` container, and any write in one process is visible to the other.
4. After each mutation, the app calls `WidgetCenter.shared.reloadAllTimelines()`, which prompts WidgetKit to call `getTimeline(in:completion:)` on the provider, which re-reads the `StoredState` values from the shared suite.
