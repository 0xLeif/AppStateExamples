import XCTest
import AppState
import Observation
@testable import WASMCore

// MARK: - CounterTests

/// Tests for counter state mutations and the formatter dependency.
///
/// These run on the **host** toolchain (macOS / Linux) because `WASMCore`
/// has no JavaScriptKit dependency.  They validate the pure logic layer
/// independently of the browser environment.
internal final class CounterTests: XCTestCase {

    // MARK: - Setup

    @MainActor
    internal override func setUp() async throws {
        var counter = Application.state(\.counter)
        counter.value = 0
    }

    // MARK: - Increment

    @MainActor
    internal func testIncrementRaisesCounter() async {
        AppActions.increment()
        XCTAssertEqual(Application.state(\.counter).value, 1)
    }

    @MainActor
    internal func testIncrementIsAdditive() async {
        AppActions.increment()
        AppActions.increment()
        AppActions.increment()
        XCTAssertEqual(Application.state(\.counter).value, 3)
    }

    // MARK: - Decrement

    @MainActor
    internal func testDecrementLowersCounter() async {
        var counter = Application.state(\.counter)
        counter.value = 5
        AppActions.decrement()
        XCTAssertEqual(Application.state(\.counter).value, 4)
    }

    @MainActor
    internal func testDecrementBelowZeroIsAllowed() async {
        AppActions.decrement()
        XCTAssertEqual(Application.state(\.counter).value, -1)
    }

    // MARK: - Reset

    @MainActor
    internal func testResetReturnsCounterToZeroFromPositive() async {
        var counter = Application.state(\.counter)
        counter.value = 42
        AppActions.resetCounter()
        XCTAssertEqual(Application.state(\.counter).value, 0)
    }

    @MainActor
    internal func testResetReturnsCounterToZeroFromNegative() async {
        var counter = Application.state(\.counter)
        counter.value = -7
        AppActions.resetCounter()
        XCTAssertEqual(Application.state(\.counter).value, 0)
    }

    // MARK: - DefaultCounterFormatter

    func testDefaultFormatterForZero() {
        XCTAssertEqual(DefaultCounterFormatter().label(for: 0), "Zero")
    }

    func testDefaultFormatterForOne() {
        XCTAssertEqual(DefaultCounterFormatter().label(for: 1), "1 click")
    }

    func testDefaultFormatterForPlural() {
        XCTAssertEqual(DefaultCounterFormatter().label(for: 7), "7 clicks")
    }

    func testDefaultFormatterForNegative() {
        XCTAssertEqual(DefaultCounterFormatter().label(for: -3), "-3 (below zero!)")
    }

    // MARK: - Dependency injection via override

    @MainActor
    internal func testInjectedFormatterIsUsedByCounterLabel() async {
        let mockFormatter = MockFormatter(fixedLabel: "TEST_LABEL")
        let token = Application.override(\.counterFormatter, with: mockFormatter)

        var counter = Application.state(\.counter)
        counter.value = 99
        let label = AppActions.counterLabel()
        await token.cancel()

        XCTAssertEqual(label, "TEST_LABEL")
    }

    @MainActor
    internal func testOverrideCancellationRestoresLiveFormatter() async {
        let mockFormatter = MockFormatter(fixedLabel: "MOCK")
        let token = Application.override(\.counterFormatter, with: mockFormatter)
        await token.cancel()  // Immediately restore.

        var counter = Application.state(\.counter)
        counter.value = 0
        // The live formatter returns "Zero" for 0.
        XCTAssertEqual(AppActions.counterLabel(), "Zero")
    }

    // MARK: - Observation

    // `withObservationTracking` delivery is verified on Apple platforms only, matching
    // AppState's own test suite. The Observation runtime's synchronous `onChange` delivery
    // is not guaranteed by swift-corelibs on Linux/Windows. The portable state and
    // dependency logic above is exercised on every platform.
    #if !os(Linux) && !os(Windows)
    @MainActor
    internal func testCounterChangeFiresObservationCallback() async {
        let fired = FiredBox()

        withObservationTracking {
            _ = Application.state(\.counter).value
        } onChange: {
            fired.increment()
        }

        AppActions.increment()

        XCTAssertEqual(fired.count, 1)
    }
    #endif
}

// MARK: - FiredBox

#if !os(Linux) && !os(Windows)
/// Thread-safe counter for capturing `withObservationTracking` reactions from a
/// `@Sendable` `onChange` closure.
private final class FiredBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
#endif

// MARK: - MockFormatter

/// Stub formatter that always returns a fixed string — verifies DI wiring.
private struct MockFormatter: CounterFormatting {
    private let fixedLabel: String

    fileprivate init(fixedLabel: String) {
        self.fixedLabel = fixedLabel
    }

    fileprivate func label(for count: Int) -> String {
        fixedLabel
    }
}
