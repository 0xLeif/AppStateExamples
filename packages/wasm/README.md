# AppState 3.0 — WASM Example

Demonstrates **AppState 3.0 running in the browser** via [SwiftWasm](https://swiftwasm.org) and [JavaScriptKit](https://github.com/swiftwasm/JavaScriptKit).

## What this shows

| Feature | Where |
|---|---|
| `State<Int>` counter | `Application+WASMState.swift` |
| `State<[TodoItem]>` list | `Application+WASMState.swift` |
| `Dependency<any CounterFormatting>` | `Application+WASMState.swift` |
| `withObservationTracking` re-arm loop | `ObservationLoop.swift` |
| DOM rendering driven by observation | `DOMRenderer.swift` |
| JavaScriptKit event wiring | `EventWiring.swift` |
| Host-runnable unit tests (no wasm SDK needed) | `Tests/WASMCoreTests/` |

The **key insight**: AppState 3.0 makes `Application` `@Observable`.  Reading
`Application.state(\.counter).value` inside `withObservationTracking` registers
a dependency.  When the state mutates, `onChange` fires, we re-render the DOM,
and immediately re-arm the observer — a fully reactive loop with zero SwiftUI.

## Prerequisites

- Swift 6.0+ toolchain (Xcode 16+ or swift.org download)
- [SwiftWasm SDK](https://github.com/swiftwasm/swift/releases) for `wasm32-unknown-wasi`
- **[carton](https://github.com/swiftwasm/carton)** (recommended for `carton dev`)
  or a static HTTP server for manual `.wasm` serving

## Quick start with carton (recommended)

```bash
# Install carton once
brew install swiftwasm/tap/carton

# From this directory
cd packages/wasm
carton dev
# Opens http://localhost:8080 in your browser with hot-reload.
```

`carton` automatically downloads the right SwiftWasm toolchain and serves the
WASM binary.

## Manual build with the Swift SDK

```bash
# 1. Install the SwiftWasm SDK once (replace <url> with the latest release URL
#    from https://github.com/swiftwasm/swift/releases)
swift sdk install https://github.com/swiftwasm/swift/releases/download/swift-wasm-6.0-SNAPSHOT-<date>/swift-wasm-6.0-SNAPSHOT-<date>-wasm32.artifactbundle.zip

# 2. Build the wasm binary
cd packages/wasm
swift build --swift-sdk wasm32-unknown-wasi -c release

# 3. The output is at:
#    .build/release/wasm-example.wasm

# 4. Serve with carton's static server, or any CORS-friendly HTTP server:
npx serve .
# Then open index.html and update the <script src="..."> tag to point at the
# correct wasm-bootstrap loader from JavaScriptKit.
```

> **Note:** Running `swift build` without `--swift-sdk wasm32-unknown-wasi` on a
> plain macOS/Linux host **will fail** because JavaScriptKit imports
> `_CJavaScriptKit` which is only available in the SwiftWasm SDK.  This is
> expected — the executable target is browser-only.  The host toolchain can
> still build and test `WASMCore`:
>
> ```bash
> swift build --target WASMCore
> swift test               # runs WASMCoreTests on the host
> ```

## Running the host tests

The `WASMCore` library has **no JavaScriptKit dependency**, so its tests run
on any Swift 6.0+ host:

```bash
cd packages/wasm
swift test
```

## Project layout

```
packages/wasm/
  Package.swift
  index.html                        # Browser entry point (carton serves this)
  Sources/
    WASMCore/                       # Pure logic — no JavaScriptKit
      Application+WASMState.swift   # State & Dependency definitions
      AppActions.swift              # @MainActor mutations
      TodoItem.swift                # Value type
      Formatting.swift              # Protocol + live implementation
    wasm-example/                   # Browser executable — requires wasm SDK
      main.swift                    # Entry point
      ObservationLoop.swift         # withObservationTracking re-arm loop
      DOMRenderer.swift             # DOM writes via JavaScriptKit
      EventWiring.swift             # Button/form event wiring
  Tests/
    WASMCoreTests/
      CounterTests.swift
      TodoTests.swift
```

## Architecture

```
  Browser button click
         │
         ▼
  EventWiring (JSClosure)
         │  calls
         ▼
  AppActions.increment() / addTodo(text:) / ...
         │  mutates
         ▼
  Application.state(\.counter).value  (AppState 3.0 @Observable)
         │  triggers
         ▼
  withObservationTracking onChange
         │  calls
         ▼
  DOMRenderer.render()   →  JavaScriptKit DOM writes
         │  then
         ▼
  ObservationLoop.arm()  (re-arms the observer)
```

The loop is purely reactive: no polling, no timers, no Combine publishers.
