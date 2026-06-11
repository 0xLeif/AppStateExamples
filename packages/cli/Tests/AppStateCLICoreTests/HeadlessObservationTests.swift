import XCTest
import AppState
import Observation
@testable import AppStateCLICore

// MARK: - HeadlessObservationTests

/// Verifies that `withObservationTracking` fires its `onChange` closure when
/// an `Application` state value is mutated — the headline AppState 3.0 feature.
final class HeadlessObservationTests: XCTestCase {

    // MARK: - Sendable Helper

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

    /// Thread-safe string collector for use inside `@Sendable` closures.
    private final class StringCollector: @unchecked Sendable {
        private let lock = NSLock()
        private var _lines: [String] = []
        var lines: [String] {
            lock.lock(); defer { lock.unlock() }
            return _lines
        }
        func append(_ line: String) {
            lock.lock(); defer { lock.unlock() }
            _lines.append(line)
        }
    }

    // MARK: - Setup

    @MainActor
    override func setUp() async throws {
        var selectionState = Application.state(\.selectedItemIndex)
        selectionState.value = nil
        var itemsState = Application.fileState(\.items)
        itemsState.value = []
    }

    // MARK: - Single-shot onChange

    /// `onChange` must fire exactly once for a single mutation.
    @MainActor
    func testOnChangeFiredForSingleMutation() async {
        let counter = Counter()

        withObservationTracking {
            _ = Application.state(\.selectedItemIndex).value
        } onChange: { [counter] in
            counter.increment()
        }

        var selectionState = Application.state(\.selectedItemIndex)
        selectionState.value = 7

        await _Concurrency.Task.yield()

        XCTAssertEqual(counter.value, 1, "onChange should fire exactly once per tracking cycle")
    }

    /// After `onChange` fires it must NOT fire again unless re-armed.
    @MainActor
    func testOnChangeDoesNotFireTwiceWithoutRearm() async {
        let counter = Counter()

        withObservationTracking {
            _ = Application.state(\.selectedItemIndex).value
        } onChange: { [counter] in
            counter.increment()
        }

        var selectionState = Application.state(\.selectedItemIndex)
        selectionState.value = 1
        selectionState.value = 2

        await _Concurrency.Task.yield()
        await _Concurrency.Task.yield()

        XCTAssertEqual(counter.value, 1, "onChange must not fire a second time without re-arming")
    }

    // MARK: - Re-armed observation

    /// Re-arming inside `onChange` must allow continuous observation.
    @MainActor
    func testRearmingCapturesAllMutations() async {
        let expectedMutations = 4

        // Encapsulate both the collection and the re-arming logic in a class
        // so the `onChange` closure can capture `self` as `@Sendable`.
        final class RearmingObserver: @unchecked Sendable {
            private let lock = NSLock()
            private var _observed: [Int?] = []
            let expected: Int

            init(expected: Int) {
                self.expected = expected
            }

            var observed: [Int?] {
                lock.lock(); defer { lock.unlock() }
                return _observed
            }

            var count: Int {
                lock.lock(); defer { lock.unlock() }
                return _observed.count
            }

            func record(_ value: Int?) {
                lock.lock(); defer { lock.unlock() }
                _observed.append(value)
            }

            /// Arms one observation cycle; re-arms inside `onChange` until `expected` fires.
            @MainActor
            func arm() {
                withObservationTracking {
                    _ = Application.state(\.selectedItemIndex).value
                } onChange: { [self] in
                    _Concurrency.Task { @MainActor in
                        self.record(Application.state(\.selectedItemIndex).value)
                        if self.count < self.expected {
                            self.arm()
                        }
                    }
                }
            }
        }

        let observer = RearmingObserver(expected: expectedMutations)
        observer.arm()

        var selectionState = Application.state(\.selectedItemIndex)
        for value in 1...expectedMutations {
            selectionState.value = value
            await _Concurrency.Task.yield()
        }

        // Drain remaining async work.
        for _ in 0..<10 {
            await _Concurrency.Task.yield()
        }

        XCTAssertEqual(observer.observed.count, expectedMutations)
        XCTAssertEqual(observer.observed.compactMap { $0 }, [1, 2, 3, 4])
    }

    // MARK: - ObservationDemo integration

    @MainActor
    func testObservationDemoProducesOutput() async {
        let collector = StringCollector()

        await ObservationDemo.run(mutationCount: 3) { [collector] line in
            collector.append(line)
        }

        let combined = collector.lines.joined(separator: "\n")
        XCTAssertTrue(
            combined.contains("Observation demo complete"),
            "Demo did not emit completion line. Got:\n\(combined)"
        )
        XCTAssertTrue(
            combined.contains("onChange"),
            "Demo did not emit any onChange lines. Got:\n\(combined)"
        )
        // Three mutations means three onChange lines plus header, "watching" line, and footer = 6 total.
        XCTAssertEqual(collector.lines.count, 6, "Expected 6 output lines. Got:\n\(combined)")
    }
}
