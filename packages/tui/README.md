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
swift run appstate-tui          # interactive dashboard
swift run appstate-tui demo     # non-interactive observation proof
```

From the package directory (`packages/tui/`).

The interactive loop applies exactly one command per keypress and re-renders
synchronously, so it is deterministic under scripted/piped input:

```
$ printf 'i\ni\ni\nw\nq\n' | swift run appstate-tui | grep 'Counter :' | tail -1
│Counter : 3                                     │
```

## Live observation note

`demo` mode proves headless observation fires live: it arms a `withObservationTracking`
observer, performs a fixed sequence of mutations, and reports each reaction —

```
$ swift run appstate-tui demo
  Reaction 1: counter=1  temp=20.0°C  paused=false
  ...
  Observer reacted 5 time(s) to 5 mutation(s).
```

This is Apple-only: `withObservationTracking` delivery is not available in AppState on
Linux/Windows (see the repo README and AppState#150). The interactive dashboard works on
all platforms because it re-renders synchronously after each command rather than relying
on observation.

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
