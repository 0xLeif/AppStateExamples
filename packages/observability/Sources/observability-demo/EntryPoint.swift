import AppState
import AppStateObservability
import Foundation
import Observation

// MARK: - Property wrapper holders for headless observation
//
// `registerObservation()` — the call that wires a code path into the Observation
// tracking graph — is invoked by:
//   • `Application.state(_:)` (the static function used throughout the demo)
//   • Any `@AppState`, `@StoredState`, `@FileState`, `@Slice` property wrapper getter
//
// For `StoredState`, `FileState`, and `Slice` headless demos we use small
// `@MainActor` structs. Their nonmutating wrapper setters write through to
// application storage, so holder instances can remain constants.

@MainActor
fileprivate struct DemoStoredStateHolder {
    @StoredState(\.lastEvent) fileprivate var lastEvent: String
}

@MainActor
fileprivate struct DemoFileStateHolder {
    @FileState(\.observationLog) fileprivate var observationLog: [String]?
}

@MainActor
fileprivate struct DemoSliceHolder {
    @Slice(\.userProfile, \.score) fileprivate var score: Int
    @Slice(\.userProfile, \.displayName) fileprivate var displayName: String
}

// MARK: - Demo Entry Point

/// Narrated walkthrough of every AppState 3.0 observability feature.
///
/// Run with: `swift run observability-demo`
@main
@MainActor
internal struct ObservabilityDemo {

    internal static func main() async {
        print(banner("AppState 3.0 — Observation Without SwiftUI"))

        await demo1_basicHeadlessObservation()
        await demo2_multipleIndependentObservers()
        await demo3_observingAcrossStateTypes()
        await demo4_sliceObservation()
        await demo5_manualNotifyChange()
        await demo6_asyncStreamBridge()

        print("\n" + banner("All demos complete"))
    }

    // MARK: - Demo 1: Basic Headless Observation

    /// Demonstrates the fundamental `withObservationTracking` pattern without any SwiftUI.
    ///
    /// ## AppState 2.x vs 3.0
    /// In 2.x, observing state required a SwiftUI view bound to an `ObservableObject`.
    /// In 3.0, `Application` is `@Observable`, so any code — CLI, actor, server task —
    /// can call `withObservationTracking` and react to state changes.
    private static func demo1_basicHeadlessObservation() async {
        printSection("Demo 1 — Basic headless observation + re-arming")

        // Reset to known baseline.
        AppStateMutation.setCounter(0)
        await Task.yield()
        await Task.yield()

        // 1a: One-shot observation via the raw API.
        //
        // `withObservationTracking` fires `onChange` exactly once — on the next
        // mutation after registration. Re-arm inside `onChange` for continuous watching.
        print("  [1a] One-shot: arming observer on 'counter'")
        var oneShotFired = false
        // Note: `oneShotFired` is captured from the @MainActor test scope;
        // because `onChange` fires synchronously on the main thread we can
        // safely assign it directly without a wrapper class.
        observeOnce({ Application.state(\.counter).value }) { newValue in
            print("  [1a] onChange fired — counter = \(newValue)")
            oneShotFired = true
        }

        AppStateMutation.setCounter(1)
        await Task.yield()
        await Task.yield()
        print("  [1a] One-shot fired: \(oneShotFired)")

        // 1b: Second mutation — observer already expired; nothing fires.
        print("  [1b] Second mutation after one-shot expires — no further fire expected")
        AppStateMutation.setCounter(2)
        await Task.yield()
        await Task.yield()

        // 1c: Continuous observation via StateObserver (re-arms automatically).
        //
        // `StateObserver` wraps the re-arm pattern and accumulates a reaction log,
        // making it easy to observe over time in any headless context.
        print("\n  [1c] Continuous observation via StateObserver")
        let observer = StateObserver(label: "counter") {
            Application.state(\.counter).value
        }
        observer.start()

        for nextValue in 3...7 {
            AppStateMutation.setCounter(nextValue)
            await Task.yield()
            await Task.yield()
        }

        observer.stop()
        print("  [1c] Log entries received: \(observer.reactionLog.count)")
        observer.reactionLog.forEach { print("       \($0)") }

        // Reset for subsequent demos.
        AppStateMutation.setCounter(0)
        await Task.yield()
        await Task.yield()
    }

    // MARK: - Demo 2: Multiple Independent Observers

    /// Shows that registering N observers against the same state causes all N to fire
    /// on a single mutation — a broadcast, not a unicast.
    ///
    /// Because AppState 3.0 has a single `@Observable` anchor, every registered
    /// `withObservationTracking` scope fires when any state changes. The
    /// `BroadcastTracker` helper registers N scopes and counts how many fire.
    private static func demo2_multipleIndependentObservers() async {
        printSection("Demo 2 — Multiple independent observers fire on one mutation")

        let tracker = BroadcastTracker()
        let observerCount = 5

        for index in 1...observerCount {
            tracker.register(label: "observer-\(index)") {
                Application.state(\.counter).value
            }
        }

        print("  Registered \(observerCount) observers. Mutating counter once…")
        AppStateMutation.setCounter(99)
        await Task.yield()
        await Task.yield()

        print("  Observers that fired: \(tracker.fireCount) / \(observerCount)")
        tracker.firedLabels.sorted().forEach { print("    fired: \($0)") }

        AppStateMutation.setCounter(0)
        await Task.yield()
        await Task.yield()
    }

    // MARK: - Demo 3: Observing Across State Types

    /// Proves that `State`, `StoredState`, and `FileState` all participate in Observation.
    ///
    /// ## Registration note
    /// `registerObservation()` is called by:
    ///  - `Application.state(_:)` static function (used for `State`)
    ///  - `@StoredState`, `@FileState` property wrapper getters
    ///
    /// The demo uses property wrapper holders so that `StoredState` and `FileState`
    /// reads correctly register in the tracking scope — matching how production code
    /// uses these wrappers in view models and services.
    private static func demo3_observingAcrossStateTypes() async {
        printSection("Demo 3 — State, StoredState, and FileState all drive observation")

        // State — read via Application.state(_:) which calls registerObservation().
        let stateObserver = StateObserver(label: "temperature(State)") {
            Application.state(\.temperature).value
        }

        // StoredState — read via @StoredState property wrapper which calls registerObservation().
        // The wrapper's nonmutating setter writes through to application storage.
        let storedHolder = DemoStoredStateHolder()
        let storedObserver = StateObserver(label: "lastEvent(StoredState)") {
            storedHolder.lastEvent
        }

        // FileState — read via @FileState property wrapper which calls registerObservation().
        let fileHolder = DemoFileStateHolder()
        let fileObserver = StateObserver(label: "observationLog(FileState)") {
            fileHolder.observationLog?.count ?? 0
        }

        stateObserver.start()
        storedObserver.start()
        fileObserver.start()

        print("  Mutating temperature (State)…")
        AppStateMutation.setTemperature(37.5)
        await Task.yield()
        await Task.yield()

        print("  Mutating lastEvent (StoredState)…")
        storedHolder.lastEvent = "demo3"
        await Task.yield()
        await Task.yield()

        print("  Mutating observationLog (FileState)…")
        fileHolder.observationLog = ["demo3-entry"]
        await Task.yield()
        await Task.yield()

        stateObserver.stop()
        storedObserver.stop()
        fileObserver.stop()

        print("  State observer log:       \(stateObserver.reactionLog)")
        print("  StoredState observer log: \(storedObserver.reactionLog)")
        print("  FileState observer log:   \(fileObserver.reactionLog)")

        // Cleanup.
        AppStateMutation.setTemperature(20.0)
        AppStateMutation.setLastEvent("none")
        AppStateMutation.setObservationLog(nil)
        await Task.yield()
        await Task.yield()
    }

    // MARK: - Demo 4: Slice Observation

    /// Demonstrates that observing a `Slice` of structured state fires whenever the
    /// parent state changes. Uses `@Slice` property wrappers for observation registration.
    ///
    /// Because AppState 3.0 uses a single anchor, both slice observers fire on every
    /// mutation to `userProfile` — regardless of which sub-property changed.
    private static func demo4_sliceObservation() async {
        printSection("Demo 4 — Slice observation of sub-properties via @Slice wrapper")

        let sliceHolder = DemoSliceHolder()

        let scoreObserver = StateObserver(label: "userProfile.score (Slice)") {
            sliceHolder.score
        }
        scoreObserver.start()

        let nameObserver = StateObserver(label: "userProfile.displayName (Slice)") {
            sliceHolder.displayName
        }
        nameObserver.start()

        print("  Mutating userProfile.score…")
        var profile = Application.state(\.userProfile).value
        profile.score = 100
        AppStateMutation.setUserProfile(profile)
        await Task.yield()
        await Task.yield()

        print("  Mutating userProfile.displayName…")
        profile.displayName = "LeifObserver"
        AppStateMutation.setUserProfile(profile)
        await Task.yield()
        await Task.yield()

        scoreObserver.stop()
        nameObserver.stop()

        print("  Score slice log:       \(scoreObserver.reactionLog)")
        print("  DisplayName slice log: \(nameObserver.reactionLog)")

        // Reset.
        AppStateMutation.setUserProfile(UserProfile(displayName: "Anonymous", score: 0))
        await Task.yield()
        await Task.yield()
    }

    // MARK: - Demo 5: Manual Broadcast Change

    /// Shows that calling `AppStateMutation.broadcastChange()` — which writes a
    /// state value back to itself — fires `notifyChange()` and wakes all observers.
    ///
    /// ## When is this useful?
    /// When an out-of-band event (e.g. an incoming iCloud change, a WebSocket push,
    /// or a file system notification) modifies state through a path that doesn't
    /// go through AppState's own setters, you can call `broadcastChange()` to
    /// signal the Observation graph to wake up.
    private static func demo5_manualNotifyChange() async {
        printSection("Demo 5 — broadcastChange() wakes observers via notifyChange()")

        let observer = StateObserver(label: "counter (broadcast)") {
            Application.state(\.counter).value
        }
        observer.start()

        print("  Calling broadcastChange() (writes counter value to itself)…")
        AppStateMutation.broadcastChange()
        await Task.yield()
        await Task.yield()

        print("  Observer fired: \(observer.reactionLog.count > 0)")
        print("  Log: \(observer.reactionLog)")
        observer.stop()

        AppStateMutation.setCounter(0)
        await Task.yield()
        await Task.yield()
    }

    // MARK: - Demo 6: AsyncStream Bridge

    /// Wraps `withObservationTracking` in an `AsyncStream<Value>` so callers can use
    /// `for await` instead of managing manual re-arming.
    ///
    /// ## Why this pattern matters
    /// `withObservationTracking` is callback-oriented. `ObservationStream` converts
    /// that pattern into idiomatic Swift concurrency, making state changes:
    ///  - Composable with `Task` cancellation
    ///  - Trivially interoperable with `AsyncSequence` combinators
    ///  - Backpressure-aware via `AsyncStream.Continuation.BufferingPolicy`
    ///
    /// The stream yields an immediate snapshot of the current value before the
    /// first mutation, ensuring consumers always start with a baseline reading.
    private static func demo6_asyncStreamBridge() async {
        printSection("Demo 6 — AsyncStream bridge for for-await consumption")

        let stream = ObservationStream.make(label: "counter") {
            Application.state(\.counter).value
        }

        // Collect 4 values: the initial snapshot + 3 mutations.
        let collectionTask = Task {
            await collect(stream, count: 4)
        }

        // Give the stream time to yield its initial value before we mutate.
        await Task.yield()

        print("  Emitting 3 counter mutations…")
        for value in [10, 20, 30] {
            AppStateMutation.setCounter(value)
            await Task.yield()
            await Task.yield()
        }

        let collected = await collectionTask.value
        print("  Values received from stream: \(collected)")
        // Expected: [0, 10, 20, 30]  (initial snapshot + 3 mutations)

        AppStateMutation.setCounter(0)
        await Task.yield()
        await Task.yield()
    }

    // MARK: - Formatting Helpers

    private static func banner(_ title: String) -> String {
        let line = String(repeating: "=", count: 60)
        return "\n\(line)\n  \(title)\n\(line)"
    }

    private static func printSection(_ title: String) {
        let line = String(repeating: "-", count: 50)
        print("\n\(line)\n  \(title)\n\(line)")
    }
}
