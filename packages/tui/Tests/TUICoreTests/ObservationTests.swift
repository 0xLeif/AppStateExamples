#if !os(Linux) && !os(Windows)
import XCTest
import AppState
import Observation
@testable import TUICore

// MARK: - ObservationTests

/// Verifies that `withObservationTracking` fires `onChange` when AppState scalar
/// state is mutated — the headline AppState 3.0 headless observation feature.
///
/// Gated behind `#if !os(Linux) && !os(Windows)` because `onChange` delivery
/// is Apple-only in AppState.
final class ObservationTests: XCTestCase {

    // MARK: - Sendable Helpers

    /// Thread-safe integer counter for use inside `@Sendable` closures.
    private final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var _value = 0

        var value: Int {
            lock.lock(); defer { lock.unlock() }
            return _value
        }

        func increment() {
            lock.lock(); defer { lock.unlock() }
            _value += 1
        }
    }

    /// Thread-safe box for a single `Bool` flag.
    private final class BoolBox: @unchecked Sendable {
        private let lock = NSLock()
        private var _value = false

        var value: Bool {
            lock.lock(); defer { lock.unlock() }
            return _value
        }

        func set(_ newValue: Bool) {
            lock.lock(); defer { lock.unlock() }
            _value = newValue
        }
    }

    // MARK: - Setup

    @MainActor
    override func setUp() async throws {
        var counter = Application.state(\.counter)
        counter.value = 0
        var temperature = Application.state(\.temperature)
        temperature.value = 20.0
        var paused = Application.state(\.paused)
        paused.value = false
    }

    // MARK: - Counter Observation

    /// `onChange` must fire exactly once when the counter state changes.
    @MainActor
    func testOnChangeFiredForCounterMutation() async {
        let fired = Counter()

        withObservationTracking {
            _ = Application.state(\.counter).value
        } onChange: { [fired] in
            fired.increment()
        }

        DashboardController.apply(.increment)
        await _Concurrency.Task.yield()

        XCTAssertEqual(fired.value, 1, "onChange must fire once per tracking cycle")
    }

    /// `onChange` must NOT fire again after being consumed, unless re-armed.
    @MainActor
    func testOnChangeIsOneShotWithoutRearm() async {
        let fired = Counter()

        withObservationTracking {
            _ = Application.state(\.counter).value
        } onChange: { [fired] in
            fired.increment()
        }

        DashboardController.apply(.increment)
        DashboardController.apply(.increment)

        await _Concurrency.Task.yield()
        await _Concurrency.Task.yield()

        XCTAssertEqual(fired.value, 1, "onChange must not fire a second time without re-arming")
    }

    // MARK: - Temperature Observation

    /// `onChange` fires when temperature state changes.
    @MainActor
    func testOnChangeFiredForTemperatureMutation() async {
        let fired = BoolBox()

        withObservationTracking {
            _ = Application.state(\.temperature).value
        } onChange: { [fired] in
            fired.set(true)
        }

        DashboardController.apply(.warmer)
        await _Concurrency.Task.yield()

        XCTAssertTrue(fired.value, "onChange should fire after temperature mutation")
    }

    // MARK: - Paused Observation

    /// `onChange` fires when paused state toggles.
    @MainActor
    func testOnChangeFiredForPausedMutation() async {
        let fired = BoolBox()

        withObservationTracking {
            _ = Application.state(\.paused).value
        } onChange: { [fired] in
            fired.set(true)
        }

        DashboardController.apply(.togglePause)
        await _Concurrency.Task.yield()

        XCTAssertTrue(fired.value, "onChange should fire after paused mutation")
    }

    // MARK: - Re-armed Continuous Observation

    /// Re-arming inside `onChange` should allow capturing multiple sequential mutations.
    @MainActor
    func testRearmingCapturesMultipleMutations() async {
        let expectedMutations = 3

        final class RearmingObserver: @unchecked Sendable {
            private let lock = NSLock()
            private var _count = 0
            let expected: Int

            init(expected: Int) {
                self.expected = expected
            }

            var count: Int {
                lock.lock(); defer { lock.unlock() }
                return _count
            }

            func increment() {
                lock.lock(); defer { lock.unlock() }
                _count += 1
            }

            @MainActor
            func arm() {
                withObservationTracking {
                    _ = Application.state(\.counter).value
                } onChange: { [self] in
                    _Concurrency.Task { @MainActor in
                        self.increment()
                        if self.count < self.expected {
                            self.arm()
                        }
                    }
                }
            }
        }

        let observer = RearmingObserver(expected: expectedMutations)
        observer.arm()

        for _ in 0..<expectedMutations {
            DashboardController.apply(.increment)
            await _Concurrency.Task.yield()
        }

        // Drain remaining async tasks.
        for _ in 0..<10 {
            await _Concurrency.Task.yield()
        }

        XCTAssertEqual(observer.count, expectedMutations,
                       "Re-armed observer should capture all \(expectedMutations) mutations")
    }

    // MARK: - Reset Observation

    /// Observing counter, then resetting all state, fires the counter onChange.
    @MainActor
    func testOnChangeFiredOnReset() async {
        // First move counter to a non-zero value.
        DashboardController.apply(.increment)

        let fired = BoolBox()

        withObservationTracking {
            _ = Application.state(\.counter).value
        } onChange: { [fired] in
            fired.set(true)
        }

        DashboardController.apply(.reset)
        await _Concurrency.Task.yield()

        XCTAssertTrue(fired.value, "onChange should fire when reset brings counter back to 0")
    }
}
#endif
