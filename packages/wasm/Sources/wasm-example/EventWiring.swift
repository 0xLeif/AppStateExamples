#if canImport(JavaScriptKit)
import JavaScriptKit
import WASMCore

// MARK: - EventWiring

/// Attaches JavaScript event listeners to the static HTML buttons and form.
///
/// `JSClosure` objects are stored in `retainedClosures` to prevent Swift's ARC
/// from releasing them while JavaScript holds a live reference.
///
/// ## Concurrency note
/// `JSClosure` callbacks are `([JSValue]) -> JSValue` — not `@MainActor`.
/// SwiftWasm runs on a single thread, so all JS callbacks fire on what is
/// effectively the main actor.  We use `MainActor.assumeIsolated` to bridge
/// this gap safely and satisfy Swift 6 strict-concurrency checking.
@MainActor
internal enum EventWiring {

    // MARK: - Retained closures

    /// All active `JSClosure` instances for page-lifetime buttons.
    private static var retainedClosures: [JSClosure] = []

    // MARK: - Setup

    /// Wires all buttons and the todo form described in `index.html` to
    /// `AppActions` mutations.
    internal static func setup() {
        let document = JSObject.global.document
        wireButton(in: document, id: "btn-increment") { AppActions.increment() }
        wireButton(in: document, id: "btn-decrement") { AppActions.decrement() }
        wireButton(in: document, id: "btn-reset") { AppActions.resetCounter() }
        wireTodoForm(document: document)
    }

    // MARK: - Helpers

    /// Creates a `JSClosure` that calls `action` on the main actor and attaches
    /// it to the `onclick` property of the element with the given `id`.
    private static func wireButton(
        in document: JSValue,
        id: String,
        action: @escaping @MainActor () -> Void
    ) {
        guard let element = document.getElementById(id).object else { return }

        let closure = JSClosure { _ in
            // SwiftWasm is single-threaded — all JS callbacks fire on the main
            // thread.  `assumeIsolated` lets us call @MainActor code without a
            // Task hop and without unsafe concurrency casts.
            MainActor.assumeIsolated { action() }
            return .undefined
        }

        element.onclick = .object(closure)
        retainedClosures.append(closure)
    }

    /// Wires the "Add" button to read the `#todo-input` field and call
    /// `AppActions.addTodo(text:)`, then clears the input.
    private static func wireTodoForm(document: JSValue) {
        guard let addButton = document.getElementById("btn-add-todo").object else { return }

        let closure = JSClosure { _ -> JSValue in
            MainActor.assumeIsolated {
                guard let input = document.getElementById("todo-input").object else { return }
                let text = input.value.string ?? ""
                AppActions.addTodo(text: text)
                input.value = .string("")
            }
            return .undefined
        }

        addButton.onclick = .object(closure)
        retainedClosures.append(closure)
    }
}
#endif
