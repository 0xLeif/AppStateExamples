#if canImport(JavaScriptKit)
import AppState
import JavaScriptKit
import WASMCore

// MARK: - DOMRenderer

/// Renders the current `Application` state into the browser DOM.
///
/// Every entry-point method is `@MainActor` — SwiftWasm is single-threaded, so
/// `@MainActor` is always satisfied and JavaScriptKit DOM calls are safe.
///
/// ## JSClosure lifecycle
/// `JSClosure` objects are reference-counted on the Swift side.  Passing one to
/// `addEventListener` does NOT transfer ownership to JavaScript — the Swift side
/// must retain it for as long as the callback might fire.
///
/// `renderTodos` rebuilds the entire `<ul>` on every render, so it replaces
/// `todoClosures` with a fresh array.  Old closures are released when the array
/// is replaced, which is safe because the old `<li>` nodes have already been
/// removed from the DOM via `innerHTML = ""`.
///
/// ## Concurrency note
/// `JSClosure` callbacks are not `@MainActor`-isolated.  We use
/// `MainActor.assumeIsolated` inside them because SwiftWasm is single-threaded
/// and all JS callbacks fire on the main thread.
@MainActor
internal enum DOMRenderer {

    // MARK: - Retained closures

    /// `JSClosure` objects for the remove buttons in the current todo render.
    /// Replaced wholesale on each `renderTodos()` call.
    private static var todoClosures: [JSClosure] = []

    // MARK: - Top-level render

    /// Performs a full re-render: counter label + todo list.
    ///
    /// Called once at startup and then by `ObservationLoop` after every state
    /// change.
    internal static func render() {
        renderCounter()
        renderTodos()
    }

    // MARK: - Counter section

    /// Writes the formatted counter label into `#counter-value`.
    private static func renderCounter() {
        let label = AppActions.counterLabel()
        let document = JSObject.global.document
        guard let element = document.getElementById("counter-value").object else { return }
        element.textContent = .string(label)
    }

    // MARK: - Todo section

    /// Rebuilds the `#todo-list` `<ul>` from the current `todos` state array.
    ///
    /// Old DOM nodes are cleared first; their event listeners can no longer fire,
    /// so it is safe to release the associated `JSClosure` objects.
    private static func renderTodos() {
        let document = JSObject.global.document
        guard let list = document.getElementById("todo-list").object else { return }

        // Detach all existing <li> nodes and release their closures.
        list.innerHTML = .string("")
        todoClosures = []

        let items = Application.state(\.todos).value

        if items.isEmpty {
            guard let empty = document.createElement("li").object else { return }
            empty.textContent = .string("No items yet — add one above!")
            empty.className = .string("empty-hint")
            _ = list.appendChild?(empty)
            return
        }

        for item in items {
            guard
                let li = document.createElement("li").object,
                let btn = document.createElement("button").object
            else { continue }

            li.textContent = .string(item.text)
            btn.textContent = .string("Remove")
            btn.className = .string("remove-btn")

            // Capture only the stable id to keep the closure lightweight.
            let capturedID = item.id
            let removeHandler = JSClosure { _ in
                // SwiftWasm is single-threaded — safe to assume main actor here.
                MainActor.assumeIsolated {
                    AppActions.removeTodo(id: capturedID)
                }
                return .undefined
            }

            // Retain on the Swift side for this render cycle.
            todoClosures.append(removeHandler)

            _ = btn.addEventListener?("click", removeHandler)
            _ = li.appendChild?(btn)
            _ = list.appendChild?(li)
        }
    }
}
#endif
