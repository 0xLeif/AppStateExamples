#if !os(Linux) && !os(Windows)
import AppState
import AppStateObservability
import Foundation
import Observation
import XCTest

// MARK: - Thread-safe mutable flags for onChange closures
//
// `withObservationTracking`'s `onChange` closure is `@Sendable`, so it cannot
// capture `var` locals isolated to a `Task` or `@MainActor`. The idiomatic
// workaround (used by AppState's own test suite) is a small
// `@unchecked Sendable` class whose methods can be called from any context.

/// A boolean latch that can be set from a `@Sendable` closure.
private final class ChangeFlag: @unchecked Sendable {
    private(set) var fired: Bool = false
    func fire() { fired = true }
    func reset() { fired = false }
}

/// An integer counter that can be incremented from a `@Sendable` closure.
private final class ChangeCounter: @unchecked Sendable {
    private(set) var count: Int = 0
    func increment() { count += 1 }
    func reset() { count = 0 }
}

// MARK: - Property wrapper holders for headless observation
//
// AppState 3.0 registers the Observation dependency only when state is read
// through:
//   • `Application.state(_:)` (the single static function that calls registerObservation)
//   • Any `@AppState`, `@StoredState`, `@FileState`, `@Slice` property wrapper getter
//
// For StoredState / FileState / Slice headless observation we therefore use small
// `@MainActor` structs with property wrappers — the same pattern as AppState's
// own ObservationBridgeTests.

@MainActor
private struct StoredStateHolder {
    @StoredState(\.lastEvent) var lastEvent: String
}

@MainActor
private struct FileStateHolder {
    @FileState(\.observationLog) var observationLog: [String]?
}

@MainActor
private struct SliceHolder {
    @Slice(\.userProfile, \.score) var score: Int
    @Slice(\.userProfile, \.displayName) var displayName: String
}

// MARK: - AppStateObservabilityTests

/// Comprehensive test suite for AppState 3.0 headless observation.
///
/// ## Key AppState 3.0 observation invariants under test
///
/// 1. `Application` has a **single global observation anchor** (`changeAnchor`).
///    Any state mutation increments this anchor, which fires ALL registered
///    `withObservationTracking` onChange callbacks — regardless of which specific
///    state they read in their apply block.
///
/// 2. Observation registration happens via `Application.state(_:)` (static) or
///    any property wrapper getter (`@AppState`, `@StoredState`, `@FileState`, …).
///    `Application.storedState(_:)`, `Application.fileState(_:)` etc. do NOT call
///    `registerObservation()`.
///
/// 3. `onChange` is one-shot per registration. Re-arm inside onChange to continue.
///
/// All tests are `@MainActor`-isolated because every AppState mutation must occur
/// on the main thread.
@MainActor
final class AppStateObservabilityTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        // Reset shared state to known baselines before each test.
        AppStateMutation.setCounter(0)
        AppStateMutation.setTemperature(20.0)
        AppStateMutation.setUnrelatedFlag(false)
        AppStateMutation.setLastEvent("none")
        AppStateMutation.setObservationLog(nil)
        AppStateMutation.setUserProfile(UserProfile(displayName: "Anonymous", score: 0))
        // Drain any pending main-queue dispatches from previous tests.
        await Task.yield()
        await Task.yield()
    }

    // MARK: - Test 1: onChange fires on mutation

    /// `withObservationTracking` must fire its `onChange` closure after a mutation.
    func test_onChange_firesOnMutation() async throws {
        let flag = ChangeFlag()

        withObservationTracking {
            _ = Application.state(\.counter).value
        } onChange: {
            flag.fire()
        }

        AppStateMutation.setCounter(42)
        await Task.yield()
        await Task.yield()

        XCTAssertTrue(flag.fired, "onChange must fire after a counter mutation")
    }

    // MARK: - Test 2: Single anchor — any mutation fires registered observers

    /// AppState 3.0 uses a single global observation anchor (`changeAnchor`).
    /// Mutating ANY state fires ALL active observers, even those registered against
    /// a different state. This is by design — the anchor is application-wide.
    func test_singleAnchor_anyMutationFiresRegisteredObservers() async throws {
        let flag = ChangeFlag()

        // Register against `counter`.
        withObservationTracking {
            _ = Application.state(\.counter).value
        } onChange: {
            flag.fire()
        }

        // Mutate `unrelatedFlag` — different state, same anchor.
        AppStateMutation.setUnrelatedFlag(true)
        await Task.yield()
        await Task.yield()

        XCTAssertTrue(
            flag.fired,
            "AppState 3.0 uses a single observation anchor — any mutation fires registered observers"
        )
    }

    // MARK: - Test 3: One-shot semantics

    /// `withObservationTracking` fires exactly once; after that, further mutations
    /// to the same state do not trigger the same `onChange`.
    func test_onChange_isOneShot() async throws {
        let counter = ChangeCounter()

        withObservationTracking {
            _ = Application.state(\.counter).value
        } onChange: {
            counter.increment()
        }

        AppStateMutation.setCounter(1)
        await Task.yield()
        await Task.yield()
        AppStateMutation.setCounter(2)
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(counter.count, 1, "A single registration should fire at most once")
    }

    // MARK: - Test 4: Re-arming produces continuous observation

    /// Verifies that manually re-arming inside `onChange` causes the observer to fire
    /// for each subsequent mutation.
    func test_reArming_continuesAcrossMultipleMutations() async throws {
        let collector = RearmingLogCollector()
        collector.start()

        let mutations = [1, 2, 3, 4, 5]
        for value in mutations {
            AppStateMutation.setCounter(value)
            await Task.yield()
            await Task.yield()
        }

        XCTAssertEqual(collector.log, mutations, "Re-armed observer must capture every mutation in order")
    }

    // MARK: - Test 5: StateObserver collects log entries

    /// `StateObserver` must populate `reactionLog` for each mutation while active.
    func test_stateObserver_collectsLogEntries() async throws {
        let observer = StateObserver(label: "counter") {
            Application.state(\.counter).value
        }
        observer.start()

        for value in 1...5 {
            AppStateMutation.setCounter(value)
            await Task.yield()
            await Task.yield()
        }

        observer.stop()

        XCTAssertEqual(
            observer.reactionLog.count, 5,
            "StateObserver must record one entry per mutation"
        )
    }

    // MARK: - Test 6: StateObserver stops after stop()

    /// After `stop()`, further mutations must not append new log entries beyond
    /// the one potentially caught during the final re-arm window.
    func test_stateObserver_stopsAfterStop() async throws {
        let observer = StateObserver(label: "counter") {
            Application.state(\.counter).value
        }
        observer.start()

        AppStateMutation.setCounter(1)
        await Task.yield()
        await Task.yield()

        let countAfterFirst = observer.reactionLog.count
        observer.stop()

        AppStateMutation.setCounter(2)
        await Task.yield()
        await Task.yield()
        AppStateMutation.setCounter(3)
        await Task.yield()
        await Task.yield()

        // At most one more entry may arrive (the pending onChange that discovered
        // isObserving == false before stopping). No further re-arms happen.
        XCTAssertLessThanOrEqual(
            observer.reactionLog.count, countAfterFirst + 1,
            "StateObserver must not accumulate entries after stop()"
        )
    }

    // MARK: - Test 7: Multiple independent observers all fire

    /// Registering N observers against the same state must cause all N `onChange`
    /// callbacks to fire on a single mutation.
    func test_multipleObservers_allFireOnOneMutation() async throws {
        let tracker = BroadcastTracker()
        let count = 4

        for index in 1...count {
            tracker.register(label: "obs-\(index)") {
                Application.state(\.counter).value
            }
        }

        AppStateMutation.setCounter(77)
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(tracker.fireCount, count, "All \(count) observers must fire on one mutation")
        XCTAssertEqual(tracker.firedLabels.count, count)
    }

    // MARK: - Test 8: Observing StoredState via property wrapper

    /// `@StoredState` property wrapper getter calls `registerObservation()`, so
    /// mutations to that state fire observers registered through the wrapper.
    func test_storedState_participatesInObservation() async throws {
        let flag = ChangeFlag()
        let holder = StoredStateHolder()

        withObservationTracking {
            _ = holder.lastEvent
        } onChange: {
            flag.fire()
        }

        var mutation = StoredStateHolder()
        mutation.lastEvent = "test8"
        await Task.yield()
        await Task.yield()

        XCTAssertTrue(flag.fired, "StoredState mutation must fire observation onChange")
    }

    // MARK: - Test 9: Observing FileState via property wrapper

    /// `@FileState` property wrapper getter calls `registerObservation()`, so
    /// mutations to that state fire observers registered through the wrapper.
    func test_fileState_participatesInObservation() async throws {
        let flag = ChangeFlag()
        let holder = FileStateHolder()

        withObservationTracking {
            _ = holder.observationLog
        } onChange: {
            flag.fire()
        }

        var mutation = FileStateHolder()
        mutation.observationLog = ["entry"]
        await Task.yield()
        await Task.yield()

        XCTAssertTrue(flag.fired, "FileState mutation must fire observation onChange")
    }

    // MARK: - Test 10: Slice observation via property wrapper

    /// `@Slice` property wrapper getter calls `registerObservation()`, so
    /// mutations to the parent state fire observers registered through the slice wrapper.
    func test_slice_firesOnSubPropertyChange() async throws {
        let flag = ChangeFlag()
        let holder = SliceHolder()

        withObservationTracking {
            _ = holder.score
        } onChange: {
            flag.fire()
        }

        var profile = Application.state(\.userProfile).value
        profile.score = 99
        AppStateMutation.setUserProfile(profile)
        await Task.yield()
        await Task.yield()

        XCTAssertTrue(flag.fired, "Slice observer must fire when the parent state changes")
    }

    // MARK: - Test 11: StateObserver on a slice

    /// `StateObserver` with a `@Slice` property wrapper read closure fires on
    /// every mutation to the parent state.
    func test_stateObserver_worksWithSlice() async throws {
        let holder = SliceHolder()
        let observer = StateObserver(label: "score-slice") {
            holder.score
        }
        observer.start()

        var profile = Application.state(\.userProfile).value
        for nextScore in [10, 20, 30] {
            profile.score = nextScore
            AppStateMutation.setUserProfile(profile)
            await Task.yield()
            await Task.yield()
        }

        observer.stop()

        XCTAssertEqual(
            observer.reactionLog.count, 3,
            "Slice observer must record one entry per parent-state mutation"
        )
    }

    // MARK: - Test 12: broadcastChange() wakes observers

    /// `AppStateMutation.broadcastChange()` writes a state value back to itself,
    /// which travels through `notifyChange()` and wakes all active observers.
    func test_broadcastChange_wakesObservers() async throws {
        let flag = ChangeFlag()

        withObservationTracking {
            _ = Application.state(\.counter).value
        } onChange: {
            flag.fire()
        }

        AppStateMutation.broadcastChange()
        await Task.yield()
        await Task.yield()

        XCTAssertTrue(flag.fired, "broadcastChange() must wake observers registered on any state")
    }

    // MARK: - Test 13: AsyncStream yields initial snapshot

    /// `ObservationStream.make` must yield the current value immediately
    /// before any mutations occur.
    func test_asyncStream_yieldsInitialSnapshot() async throws {
        AppStateMutation.setCounter(55)
        await Task.yield()
        await Task.yield()

        let stream = ObservationStream.make(label: "counter") {
            Application.state(\.counter).value
        }

        let collected = await collect(stream, count: 1)

        XCTAssertEqual(collected, [55], "Stream must yield the initial value as its first element")
    }

    // MARK: - Test 14: AsyncStream yields values in order

    /// After the initial snapshot, `ObservationStream` must yield new values in the
    /// order mutations were applied.
    func test_asyncStream_yieldsValuesInOrder() async throws {
        let stream = ObservationStream.make(label: "counter") {
            Application.state(\.counter).value
        }

        let collectionTask = Task {
            await collect(stream, count: 4)  // snapshot + 3 mutations
        }

        await Task.yield()

        for value in [10, 20, 30] {
            AppStateMutation.setCounter(value)
            await Task.yield()
            await Task.yield()
        }

        let collected = await collectionTask.value

        XCTAssertEqual(collected, [0, 10, 20, 30], "Stream must yield values in mutation order")
    }

    // MARK: - Test 15: AsyncStream consumer break stops accumulation

    /// Breaking out of the `for await` loop must stop the stream from delivering
    /// further elements to the local array.
    func test_asyncStream_stopsOnConsumerBreak() async throws {
        let stream = ObservationStream.make(label: "counter") {
            Application.state(\.counter).value
        }

        var collected: [Int] = []

        let consumer = Task {
            for await value in stream {
                collected.append(value)
                if collected.count >= 2 {
                    break
                }
            }
        }

        await Task.yield()
        AppStateMutation.setCounter(1)
        await Task.yield()
        await Task.yield()

        await consumer.value

        XCTAssertLessThanOrEqual(collected.count, 2, "Consumer break must cap element collection")
    }

    // MARK: - Test 16: StateObserver via observeOnce-style helper

    /// Using `StateObserver` proves continuous re-arming works and the log
    /// entry includes the expected mutated value.
    func test_observeOnce_stateObserverCapturesValue() async throws {
        let observer = StateObserver(label: "observeOnce") {
            Application.state(\.counter).value
        }
        observer.start()

        AppStateMutation.setCounter(123)
        await Task.yield()
        await Task.yield()

        observer.stop()

        XCTAssertTrue(
            observer.reactionLog.contains(where: { $0.contains("123") }),
            "Observer must capture the mutated value in its log"
        )
    }

    // MARK: - Test 17: One-shot does not fire after expiry

    /// After the one-shot fires, further mutations must not retrigger it.
    func test_oneShot_doesNotFireAfterExpiry() async throws {
        let counter = ChangeCounter()

        withObservationTracking {
            _ = Application.state(\.counter).value
        } onChange: {
            counter.increment()
        }

        AppStateMutation.setCounter(1)
        await Task.yield()
        await Task.yield()
        AppStateMutation.setCounter(2)
        await Task.yield()
        await Task.yield()

        XCTAssertEqual(counter.count, 1, "One-shot must fire at most once")
    }

    // MARK: - Test 18: BroadcastTracker reset clears counts

    /// `BroadcastTracker.reset()` must zero `fireCount` and empty `firedLabels`.
    func test_broadcastTracker_reset() async throws {
        let tracker = BroadcastTracker()

        tracker.register(label: "a") {
            Application.state(\.counter).value
        }

        AppStateMutation.setCounter(1)
        await Task.yield()
        await Task.yield()

        XCTAssertGreaterThan(tracker.fireCount, 0)
        tracker.reset()

        XCTAssertEqual(tracker.fireCount, 0, "reset() must zero fireCount")
        XCTAssertTrue(tracker.firedLabels.isEmpty, "reset() must clear firedLabels")
    }

    // MARK: - Test 19: collect helper drains exactly N elements

    /// `collect(_:count:)` must return exactly `count` elements and stop consuming.
    func test_collect_drainsPreciselyNElements() async throws {
        let stream = ObservationStream.make(label: "counter") {
            Application.state(\.counter).value
        }

        let collectTask = Task {
            await collect(stream, count: 3)
        }

        await Task.yield()

        for value in [5, 15, 25, 35, 45] {
            AppStateMutation.setCounter(value)
            await Task.yield()
            await Task.yield()
        }

        let result = await collectTask.value
        XCTAssertEqual(result.count, 3, "collect() must return exactly 3 elements")
    }

    // MARK: - Test 20: StateObserver clearLog

    /// `clearLog()` must empty `reactionLog` without stopping observation.
    func test_stateObserver_clearLog() async throws {
        let observer = StateObserver(label: "counter") {
            Application.state(\.counter).value
        }
        observer.start()

        AppStateMutation.setCounter(1)
        await Task.yield()
        await Task.yield()

        XCTAssertFalse(observer.reactionLog.isEmpty)
        observer.clearLog()
        XCTAssertTrue(observer.reactionLog.isEmpty, "clearLog() must empty the log")

        // Observer should still be active after clearing the log.
        AppStateMutation.setCounter(2)
        await Task.yield()
        await Task.yield()

        observer.stop()
        XCTAssertFalse(observer.reactionLog.isEmpty, "Observer must still fire after clearLog()")
    }
}

// MARK: - Test Helpers

/// A `@MainActor` helper that demonstrates manual re-arming of `withObservationTracking`
/// while satisfying Swift 6's `@Sendable` requirement on closures captured across concurrency
/// boundaries.
///
/// Because this is a `@MainActor final class`, the `[weak self]` capture in the
/// `DispatchQueue.main.async` block is `Sendable`-safe: class references are always `Sendable`,
/// and `@MainActor` ensures the log mutation happens on the right executor.
@MainActor
private final class RearmingLogCollector {

    // MARK: - Properties

    /// Ordered list of counter values captured on each `onChange` fire.
    private(set) var log: [Int] = []

    // MARK: - Methods

    /// Registers the first observation scope and begins re-arming on every change.
    func start() {
        arm()
    }

    /// Registers one observation scope and re-arms inside `onChange`.
    private func arm() {
        withObservationTracking {
            _ = Application.state(\.counter).value
        } onChange: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.log.append(Application.state(\.counter).value)
                    self.arm()
                }
            }
        }
    }
}
#endif
