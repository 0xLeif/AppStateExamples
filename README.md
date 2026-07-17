# AppState Examples

A tour of [**AppState 3.0**](https://github.com/0xLeif/AppState) across every place Swift runs — command line, server, browser (WebAssembly), and Apple platforms. Each example is independently pinned to the stable `AppState` `3.0.0` release, so the toolchains never collide.

The two things every example shows off:

- **Observation without SwiftUI** — in 2.x, AppState's reactivity was tied to SwiftUI's `ObservableObject`. In 3.0, `Application` is `@Observable`, and reading `Application.state(_:).value` participates in Observation. Any code — a CLI, a server, an actor — can react to state changes with `withObservationTracking`.
- **Dependency injection + state** that works the same everywhere, with test overrides.

![AppState 3 SwiftUI tour](docs/assets/swiftui/appstate-3-swiftui-tour.gif)

The SwiftUI tour above is assembled from screenshots captured by the app's UI-test target. The same screens also have
fixed-size light/dark image-regression snapshots, so the visual proof is backed by repeatable tests rather than a manual
recording.

## Examples

| Example | Platforms | What it shows |
| --- | --- | --- |
| [`packages/cli`](packages/cli) | macOS · Linux | A task-tracker CLI using `State`, `StoredState`, `FileState`, dependency injection, and a `watch` command that demonstrates headless observation. |
| [`packages/tui`](packages/tui) | macOS · Linux | An interactive terminal **live dashboard** — keypresses mutate scalar state and the frame re-renders, reactively via `withObservationTracking` on Apple. |
| [`packages/observability`](packages/observability) | macOS · Linux | The flagship deep-dive on 3.0 observation: re-arming, multiple observers, slices, `notifyChange()`, and an `AsyncStream` bridge over `withObservationTracking`. |
| [`packages/testing-showcase`](packages/testing-showcase) | macOS · Linux | The definitive guide to **testing** AppState code — `Application.override`, dependency mocking, controllable clocks, error paths, and state isolation. The tests *are* the docs. |
| [`packages/vapor-example`](packages/vapor-example) | macOS · Linux | A [Vapor](https://vapor.codes) JSON API using AppState as its DI container, with shared config and a headless server-side metrics observer. |
| [`packages/wasm`](packages/wasm) | WebAssembly | A browser counter/todo that drives the DOM from AppState observation via [JavaScriptKit](https://github.com/swiftwasm/JavaScriptKit). Pure logic lives in a host-testable `WASMCore` library. |
| [`apps/Pomodoro`](apps/Pomodoro) | iOS · macOS | A **real** Pomodoro timer — AppState used cohesively: live timer `State`, persisted `StoredState` settings/sessions, an injected `Ticker` dependency, and observation driving the per-second UI. |
| [`apps/SwiftUIDemo`](apps/SwiftUIDemo) | iOS · macOS | A SwiftUI catalog plus an integrated delivery workflow combining collection state, persisted preferences, async dependency injection, derived progress, an activity timeline, SwiftData, and headless observation. Snapshot tests, UI journeys, and a generated proof GIF cover the app. |
| [`apps/MenuBarDemo`](apps/MenuBarDemo) | macOS | A native menu-bar app (`MenuBarExtra`) driven by `@AppState`, `@StoredState`, `@SecureState` (Keychain), `@SyncState` (iCloud), and an overridable dependency. |
| [`apps/WidgetDemo`](apps/WidgetDemo) | iOS | A WidgetKit widget sharing `StoredState` with its host app across the process boundary via an **App Group** (AppState pointed at a shared `UserDefaults` suite). |

## Feature coverage

| Feature | cli | tui | observability | vapor | wasm | SwiftUI | Pomodoro | menubar | widget |
| --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| `@AppState` / `State` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| `StoredState` (UserDefaults) | ✅ | ✅ | ✅ | ✅ | | ✅ | ✅ | ✅ | ✅ |
| `FileState` | ✅ | | ✅ | | | ✅ | | | |
| `SyncState` (iCloud) | | | | | | ✅ | | ✅ | |
| `SecureState` (Keychain) | | | | | | ✅ | | ✅ | |
| Dependencies + overrides | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Slices | | | ✅ | | | ✅ | | | |
| Headless observation † | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| SwiftData (`@ModelState`) | | | | | | ✅ | | | |
| Snapshot + UI-test proof | | | | | | ✅ | ✅ | ✅ | ✅ |

† Every example *uses* `withObservationTracking`, and the code compiles and runs on all platforms. The observation-*delivery* assertions (that `onChange` fires) are verified on Apple platforms only — matching AppState's own test suite, since the Observation runtime's synchronous delivery isn't guaranteed by swift-corelibs on Linux/Windows. The portable `State`/dependency logic is tested everywhere.

## Running

Each package is standalone — `cd` into it and use SwiftPM:

```bash
# CLI
cd packages/cli && swift run appstate-cli add "Ship 3.0" && swift run appstate-cli list

# Interactive terminal dashboard (keys: i/d warmer/cooler w/c, p pause, r reset, q quit)
cd packages/tui && swift run appstate-tui

# Observability walkthrough
cd packages/observability && swift run observability-demo

# Vapor server
cd packages/vapor-example && swift run vapor-example   # serves on http://127.0.0.1:8080

# Tests (any package)
swift test
```

The **WASM** example needs the SwiftWasm SDK — see [`packages/wasm/README.md`](packages/wasm/README.md). The **SwiftUI** app uses [xcodegen](https://github.com/yonaskolb/XcodeGen):

```bash
cd apps/SwiftUIDemo && xcodegen generate && open SwiftUIDemo.xcodeproj
```

The repository also exposes the common verification flows through fledge:

```bash
fledge run test-packages   # all standalone SwiftPM suites
fledge run build-swiftui   # iOS + macOS compile gates
fledge run build-apple-apps # menu bar, Pomodoro, host app + widget
fledge run test-swiftui    # snapshot tests + UI journeys
fledge run coverage-swiftui # SwiftUI proof suite + 95% coverage gate
fledge run test-apple-apps # menu bar, Pomodoro, and widget proof + coverage gates
fledge run coverage-packages # all SwiftPM suites + per-package coverage gates
fledge run evidence        # rebuild the GIF from verified frames
```

## Verified coverage

The checked-in gates measure production targets, not test bundles. The latest full local run on July 17, 2026 produced:

| Target | Line coverage | Enforced minimum |
| --- | ---: | ---: |
| CLI core | 97.74% | 95% |
| TUI core | 98.05% | 95% |
| Observability | 89.90% | 85% |
| Testing showcase | 90.00% | 85% |
| Vapor core | 95.06% | 90% |
| WASM core | 100.00% | 100% |
| SwiftUIDemo app | 98.89% | 95% |
| MenuBarDemo app | 88.85% | 85% |
| Pomodoro app | 96.00% | 95% |
| WidgetDemo host app | 100.00% | 95% |
| WidgetDemo shared core | 98.03% | 95% |

The tiny WidgetKit extension entry point is compile-gated; its timeline source and every widget layout live in the
98.03%-covered shared core. Menu-bar snapshots inject a secure-state fixture, so automated tests never access or prompt
for the developer's login Keychain. The signed production app continues to use live `SecureState`.

## Platform support

AppState 3.0.0 includes the cross-platform fixes that unblock collection state on Linux and AppState itself on
WebAssembly. The six portable package suites therefore gate Linux CI. Observation-delivery assertions remain
Apple-only where the swift-corelibs runtime does not guarantee synchronous delivery; portable state and dependency
behavior is tested on every host. The stable SwiftWasm cross-compile and the 100%-covered host-side WASMCore suite are
both required gates.

## CI

GitHub Actions builds and tests every example on its native toolchain: SwiftPM on macOS and Linux, host and SwiftWasm
coverage for the browser example, all Apple app compile targets, and every Apple snapshot/UI-test suite. CI preserves
the SwiftUI, Menu Bar, Pomodoro, and Widget `.xcresult` bundles as evidence. See
[`.github/workflows`](.github/workflows).
