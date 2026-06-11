# MenuBarDemo

A native macOS menu-bar app built entirely with SwiftUI `MenuBarExtra` and AppState 3.0.

Demonstrates every major AppState state type and dependency injection, all driving a compact macOS popover — no window, no Dock icon.

---

## Setup

```bash
# From the MenuBarDemo directory:
xcodegen generate
open MenuBarDemo.xcodeproj
```

Build and run the `MenuBarDemo` scheme. A sparkle icon appears in your menu bar.

---

## What each section demonstrates

### @AppState — In-memory counter

`@AppState(\.clickCount)` reads and writes a plain `State<Int>` that lives only in memory for the app's lifetime.

- **Increment** adds 1; **Reset** returns it to 0.
- The menu-bar icon title reflects the live count — the same `@AppState` property is read in `MenuBarDemoApp`, so the SwiftUI Observation system updates the label automatically without any explicit binding or notification.

### @StoredState — Persisted greeting

`@StoredState(\.greeting)` wraps `UserDefaults` via AppState. Whatever you type survives app restarts.

- Edit the text field; the value is written to `UserDefaults` on every keystroke.
- Re-launch the app and the greeting is restored from disk.

### @SecureState — Keychain-backed token

`@SecureState(\.apiToken)` stores an optional `String` in the **login Keychain** — never in `UserDefaults` or any plain file.

- Type a token, tap **Save**; the value is written to the Keychain entry `menuBarDemoApiToken`.
- The UI always shows a masked dot-string; the **Reveal token** toggle switches between `SecureField` and `TextField` for the draft only.
- **Clear** sets the state to `nil`, which deletes the Keychain entry.

> Note: Keychain operations work without any special entitlement in debug builds. Distribution builds require the `Keychain Sharing` entitlement or a provisioning profile that includes it.

### @SyncState — iCloud-synced accent

`@SyncState(\.accentName)` reads and writes `NSUbiquitousKeyValueStore`. Selecting a different accent in the Picker propagates to every Mac and iPhone signed into the same iCloud account.

- The colour swatch updates immediately; the raw iCloud KV value is shown below.
- Full cross-device sync requires an **iCloud-capable** signing configuration (Team + iCloud KV entitlement). The state still stores and restores locally without it.

### @AppDependency + Application.override — Hot-swap service

`@AppDependency(\.greetingService)` resolves a `any GreetingProviding` dependency injected into `Application`.

- The live service (`LiveGreetingService`) prefixes the stored greeting with `✦`.
- **Use Mock** calls `Application.override(\.greetingService, with: MockGreetingService())` and stores the returned `Application.DependencyOverride` token in a `@State` property.
- **Restore Live** calls `await overrideToken?.cancel()` (wrapped in `Task { @MainActor in … }` because `cancel()` is `async`) and nils the token.
- This is the same mechanism used in XCTest — the token keeps the override alive for exactly as long as you hold it.

---

## Project structure

```
Sources/
  App/
    Info.plist               — LSUIElement = true (no Dock icon)
    MenuBarDemoApp.swift     — @main, MenuBarExtra, reads clickCount for title label
  Application/
    Application+State.swift         — clickCount, greeting
    Application+SecureSync.swift    — apiToken (Keychain), accentName (iCloud KV)
    Application+Dependencies.swift  — greetingService dependency
  Models/
    GreetingService.swift    — GreetingProviding protocol, Live + Mock implementations
  Views/
    MenuBarPopoverView.swift     — root composition view
    SectionHeaderView.swift      — reusable section header
    CounterSectionView.swift     — @AppState demo
    GreetingSectionView.swift    — @StoredState demo
    SecureTokenSectionView.swift — @SecureState demo
    AccentSyncSectionView.swift  — @SyncState demo
    DependencySectionView.swift  — @AppDependency + override demo
    QuitButtonView.swift         — NSApplication.shared.terminate
```

---

## Build requirements

- macOS 14 Sonoma or later
- Xcode 16+
- Swift 6.0
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

The package dependency (`AppState` exact `3.0.0-rc.1`) is resolved automatically by Xcode on first open.
