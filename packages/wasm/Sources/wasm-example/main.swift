#if canImport(JavaScriptKit)
import AppState
import JavaScriptKit
import WASMCore

// MARK: - Entry Point

// Enable AppState logging during development so console shows state changes.
Application.logging(isEnabled: true)

// 1. Wire DOM event listeners to AppActions mutations.
EventWiring.setup()

// 2. Perform the initial render so the page is never blank.
DOMRenderer.render()

// 3. Start the observation loop — every subsequent state mutation will
//    automatically re-render the DOM via withObservationTracking.
ObservationLoop.start()
#endif
