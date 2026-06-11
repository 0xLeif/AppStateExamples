# AppState Examples

A tour of [**AppState 3.0**](https://github.com/0xLeif/AppState) across every place Swift runs — command line, server, browser (WebAssembly), and Apple platforms. Each example is an independent Swift package pinned to `AppState` `3.0.0-rc.1`, so the toolchains never collide.

The two things every example shows off:

- **Observation without SwiftUI** — in 2.x, AppState's reactivity was tied to SwiftUI's `ObservableObject`. In 3.0, `Application` is `@Observable`, and reading `Application.state(_:).value` participates in Observation. Any code — a CLI, a server, an actor — can react to state changes with `withObservationTracking`.
- **Dependency injection + state** that works the same everywhere, with test overrides.

## Examples

| Example | Platforms | What it shows |
| --- | --- | --- |
| [`packages/cli`](packages/cli) | macOS · Linux | A task-tracker CLI using `State`, `StoredState`, `FileState`, dependency injection, and a `watch` command that demonstrates headless observation. |
| [`packages/observability`](packages/observability) | macOS · Linux | The flagship deep-dive on 3.0 observation: re-arming, multiple observers, slices, `notifyChange()`, and an `AsyncStream` bridge over `withObservationTracking`. |
| [`packages/vapor-example`](packages/vapor-example) | macOS · Linux | A [Vapor](https://vapor.codes) JSON API using AppState as its DI container, with shared config and a headless server-side metrics observer. |
| [`packages/wasm`](packages/wasm) | WebAssembly | A browser counter/todo that drives the DOM from AppState observation via [JavaScriptKit](https://github.com/swiftwasm/JavaScriptKit). Pure logic lives in a host-testable `WASMCore` library. |
| [`apps/SwiftUIDemo`](apps/SwiftUIDemo) | iOS · macOS | A SwiftUI catalog touring every state type, dependency injection + overrides, slices, SwiftData via `@ModelState`, and an observability panel proving observation works in and out of SwiftUI. |

## Feature coverage

| Feature | cli | observability | vapor | wasm | SwiftUI |
| --- | :-: | :-: | :-: | :-: | :-: |
| `@AppState` / `State` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `StoredState` (UserDefaults) | ✅ | ✅ | ✅ | | ✅ |
| `FileState` | ✅ | ✅ | | | ✅ |
| `SyncState` (iCloud) | | | | | ✅ |
| `SecureState` (Keychain) | | | | | ✅ |
| Dependencies + overrides | ✅ | ✅ | ✅ | ✅ | ✅ |
| Slices | | ✅ | | | ✅ |
| Headless observation † | ✅ | ✅ | ✅ | ✅ | ✅ |
| SwiftData (`@ModelState`) | | | | | ✅ |

† Every example *uses* `withObservationTracking`, and the code compiles and runs on all platforms. The observation-*delivery* assertions (that `onChange` fires) are verified on Apple platforms only — matching AppState's own test suite, since the Observation runtime's synchronous delivery isn't guaranteed by swift-corelibs on Linux/Windows. The portable `State`/dependency logic is tested everywhere.

## Running

Each package is standalone — `cd` into it and use SwiftPM:

```bash
# CLI
cd packages/cli && swift run appstate-cli add "Ship 3.0" && swift run appstate-cli list

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

## Platform support

**Apple platforms (iOS/macOS/tvOS/watchOS) are fully supported and gate CI.** Building these examples surfaced real gaps in AppState 3.0's non-Apple support, which are filed upstream and tracked here:

- **WebAssembly** — AppState doesn't yet build for wasm ([AppState#149](https://github.com/0xLeif/AppState/issues/149)); the `wasm-example` cross-compile is best-effort until it does.
- **Linux** — collection-typed state (`State<[T]>`, `FileState<[T]?>`) crashes at runtime ([AppState#151](https://github.com/0xLeif/AppState/issues/151)), headless observation delivery is Apple-only ([AppState#150](https://github.com/0xLeif/AppState/issues/150)), and the Swift 6.1.0 Linux toolchain mis-links Observation into a Vapor binary. The Linux/WASM CI jobs are therefore **informational** (`continue-on-error`) until those land.

Scalar state and dependency injection work on Linux today; the examples will tighten their Linux guarantees as the upstream issues close.

## CI

GitHub Actions builds and tests every example on its native toolchain — macOS (the gate), plus informational Linux, WebAssembly, and an iOS/macOS compile of the SwiftUI app. See [`.github/workflows`](.github/workflows).
