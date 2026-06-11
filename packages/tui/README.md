# appstate-tui

A live terminal dashboard powered by **AppState 3.0**, demonstrating reactive UI without SwiftUI.

## What it shows

| Feature | How it's used |
|---------|--------------|
| `State<Int>` | Counter — incremented/decremented by keypresses |
| `State<Double>` | Temperature — adjusted in 5°C steps, visualised as a gauge bar |
| `State<Bool>` | Pause flag — toggled to freeze/resume the status indicator |
| `StoredState<String>` | Dashboard label — persists across sessions via UserDefaults |
| `Dependency<any FrameStyling>` | Injected styling — swap in tests via `Application.override` |
| Headless `withObservationTracking` | Re-renders the frame on state change (Apple only) |

## Keybindings

| Key | Action |
|-----|--------|
| `i` | Increment counter |
| `d` | Decrement counter |
| `w` | Warmer (+5 °C) |
| `c` | Cooler (−5 °C) |
| `p` | Pause / resume |
| `r` | Reset all state |
| `q` | Quit |

## Running

```
swift run appstate-tui
```

From the package directory (`packages/tui/`).

## Live observation note

On **Apple platforms** (macOS 14+), the dashboard wires a `withObservationTracking` loop
that fires whenever any scalar state changes. The terminal clears and re-renders
automatically — no polling, no SwiftUI required.

On **Linux / Windows**, `onChange` delivery is not available in AppState. The dashboard
falls back to re-rendering immediately after each command, producing identical visual
output with manual trigger instead of reactive trigger.

## Architecture

```
TUICore (library)
├── Application+Dashboard.swift   — scalar state & dependency definitions
├── DashboardCommand.swift        — command enum with key mapping
├── DashboardController.swift     — apply(_:) mutator + render() ASCII renderer
└── FrameStyling.swift            — styling protocol + Default/Plain implementations

appstate-tui (executable)
└── EntryPoint.swift              — @main interactive loop + reactive observer
```

The executable is intentionally thin. All logic — mutation, rendering, styling — lives in
`TUICore` and is exercised by the unit tests without any terminal I/O.
