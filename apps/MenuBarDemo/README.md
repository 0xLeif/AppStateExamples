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

- The section does not instantiate `@SecureState` or read the Keychain when the popover opens. Tap **Enable Keychain Demo**
  to opt in first.
- macOS may request the login Keychain password if a saved item came from an older local build with a different code
  signature. The opt-in screen explains this before any access occurs.
- Type a token, tap **Save**; the value is written to the Keychain entry `menuBarDemoApiToken`.
- The UI always shows a masked dot-string; the **Reveal token** toggle switches between `SecureField` and `TextField` for the draft only.
- **Clear** sets the state to `nil`, which deletes the Keychain entry.

> Note: Keychain operations work without any special entitlement in debug builds. Distribution builds require the `Keychain Sharing` entitlement or a provisioning profile that includes it.

Snapshot and unit-test hosts intentionally inject a fixture into the secure-token presentation. They never read, write,
or request access to the developer's login Keychain. Normal signed app launches use live `@SecureState` only after the
user explicitly enables the demo.

### @SyncState — iCloud-synced accent

`@SyncState(\.accentName)` reads and writes `NSUbiquitousKeyValueStore`. Selecting a different accent in the Picker propagates to every Mac and iPhone signed into the same iCloud account.

- The colour swatch updates immediately; the raw iCloud KV value is shown below.
- Full cross-device sync requires an **iCloud-capable** signing configuration (Team + iCloud KV entitlement).
- Without that entitlement, touching `NSUbiquitousKeyValueStore` aborts the process (`BUG IN CLIENT OF KVS`), so at launch the app detects the missing entitlement and overrides AppState's `icloudStore` dependency with a local stand-in (`Application.useLocalSyncStoreIfNeeded()`). The value then stores and restores locally via the `SyncState` `UserDefaults` fallback, and the section subtitle says "Local fallback".

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
    Application+SyncFallback.swift  — local iCloud-KV fallback when the entitlement is absent
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

The package dependency (`AppState` exact `3.0.1`) is resolved automatically by Xcode on first open.

## Verification

From the repository root, `fledge run test-apple-apps` runs service/state behavior tests plus twelve macOS image
regressions covering the complete light-mode popover, every accent branch, and shared components. The latest run covered
91.86% of `MenuBarDemo.app`; CI enforces an 85% minimum. Untested lines are primarily destructive/termination button
closures that image tests render but deliberately do not invoke.
