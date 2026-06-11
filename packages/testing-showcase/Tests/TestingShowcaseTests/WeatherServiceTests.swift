import XCTest
import AppState
@testable import TestingShowcase

// MARK: - WeatherServiceTests
//
// LEARNING GUIDE
// ==============
// This test suite is the primary teaching artifact for "Testing with AppState 3.0".
// Each test is heavily commented to explain both the *what* and the *why*.
//
// Key patterns demonstrated:
//
//   1. Application.override  — swap a live dependency for a test double.
//   2. await token.cancel()  — restore the live dependency after the test.
//   3. State isolation       — reset scalar state in setUp so tests are independent.
//   4. Error-path testing    — inject a FailingWeatherProvider, assert no side-effects.
//   5. Multiple overrides    — hold several tokens simultaneously; cancel in any order.
//   6. Spy / call recording  — use SpyWeatherProvider to assert call arguments.
//   7. Monotonic time        — use MonotonicClock to assert timestamp ordering.
//   8. (Apple only)          — observation delivery via withObservationTracking, gated
//                             behind `#if !os(Linux) && !os(Windows)`.

// MARK: - WeatherServiceTests

final class WeatherServiceTests: XCTestCase {

    // MARK: - setUp
    //
    // CRITICAL: Do NOT call `super.setUp()` here.
    //
    // In Swift 6.1 with strict concurrency enabled, XCTestCase.setUp() is *not*
    // annotated @MainActor, which causes a compiler error when overriding it from
    // a @MainActor context on Linux. Omitting the super call is the correct fix —
    // XCTestCase.setUp()'s default body is empty, so nothing is lost.
    //
    // We reset ALL scalar state managed by WeatherService here so every test
    // starts from a known baseline. This is the primary isolation mechanism in
    // an AppState-based test suite.

    @MainActor
    override func setUp() async throws {
        // Reset in-memory state by assigning the initial values back.
        // Pattern: bind to a local `var` first — `Application.state(\.x).value = y`
        // does NOT compile because `state(_:)` returns a temporary value type.
        var temperature = Application.state(\.lastTemperature)
        temperature.value = 0.0

        var count = Application.state(\.refreshCount)
        count.value = 0

        var timestamp = Application.state(\.lastRefreshTimestamp)
        timestamp.value = 0

        // StoredState (UserDefaults-backed) must be reset too.
        var city = Application.storedState(\.lastCity)
        city.value = ""
    }

    // MARK: - Test 1: Basic dependency override
    //
    // PATTERN: The simplest and most common override idiom.
    //
    //   1. Call Application.override(_:with:) — returns a DependencyOverride token.
    //   2. Exercise the unit under test.
    //   3. Assert the injected mock's value appears in state.
    //   4. await token.cancel() to restore the live dependency.
    //
    // The `await` on `cancel()` is load-bearing: it waits for AppState's internal
    // actor to finish restoring the live dependency before the test returns.

    @MainActor
    func testOverridingWeatherProviderWithMockProducesExpectedTemperature() async throws {
        // 1. Arrange — inject a mock that always returns 21.0 °C.
        let mockProvider = MockWeatherProvider(fixed: 21.0)
        let token = Application.override(\.weatherProvider, with: mockProvider)

        // 2. Act — run the service; it will read the injected dependency.
        try await WeatherService.refresh(city: "London")

        // 3. Assert — state should reflect the mock's value, not the live stub's 20.0.
        XCTAssertEqual(Application.state(\.lastTemperature).value, 21.0)
        XCTAssertEqual(Application.state(\.refreshCount).value, 1)
        XCTAssertEqual(Application.storedState(\.lastCity).value, "London")

        // 4. Tear down — cancel the override so later tests use the live provider.
        //    This is analogous to `defer { overrideToken.cancel() }` but the await
        //    form guarantees the restoration completes before we continue.
        await token.cancel()
    }

    // MARK: - Test 2: Override cancellation restores the live dependency

    @MainActor
    func testCancellingOverrideRestoresLiveProvider() async throws {
        // Arrange — install a mock, then immediately cancel it.
        let mockProvider = MockWeatherProvider(fixed: 99.9)
        let token = Application.override(\.weatherProvider, with: mockProvider)
        await token.cancel() // Restore the live LiveWeatherProvider now.

        // Act — run the service; it should use the live provider (returns 20.0).
        try await WeatherService.refresh(city: "Berlin")

        // Assert — live provider's stub value (20.0), not the cancelled mock's 99.9.
        XCTAssertEqual(Application.state(\.lastTemperature).value, 20.0)
    }

    // MARK: - Test 3: Inject a controllable clock

    @MainActor
    func testStubClockProducesDeterministicTimestamp() async throws {
        // Arrange — pin time to a specific epoch second.
        let pinnedTime = 1_700_000_000
        let clockToken = Application.override(\.clock, with: StubClock(fixedNow: pinnedTime))

        // Also override the provider so we know the refresh will succeed.
        let providerToken = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 15.0))

        // Act
        try await WeatherService.refresh(city: "Oslo")

        // Assert — timestamp in state must exactly match the pinned value.
        // Without a clock override this would depend on the real system time,
        // making the assertion non-deterministic.
        XCTAssertEqual(Application.state(\.lastRefreshTimestamp).value, pinnedTime)

        await providerToken.cancel()
        await clockToken.cancel()
    }

    // MARK: - Test 4: Error path — provider failure leaves state unchanged

    @MainActor
    func testFailingProviderDoesNotMutateState() async throws {
        // Arrange — a provider that always throws.
        let failToken = Application.override(\.weatherProvider, with: FailingWeatherProvider(reason: "no network"))

        // Record state values before the (expected) failure.
        let temperatureBefore = Application.state(\.lastTemperature).value
        let countBefore = Application.state(\.refreshCount).value

        // Act — WeatherService should propagate the error without touching state.
        var caughtError: WeatherServiceError?
        do {
            try await WeatherService.refresh(city: "Nowhere")
        } catch let error as WeatherServiceError {
            caughtError = error
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        // Assert — the error was surfaced correctly…
        XCTAssertNotNil(caughtError, "Expected a WeatherServiceError to be thrown")

        // …and state was NOT mutated (refreshCount is the key invariant here).
        XCTAssertEqual(Application.state(\.refreshCount).value, countBefore,
                       "refreshCount must not increment on a failed refresh")
        XCTAssertEqual(Application.state(\.lastTemperature).value, temperatureBefore,
                       "lastTemperature must not change on a failed refresh")

        await failToken.cancel()
    }

    // MARK: - Test 5: State isolation between tests (no data leaking)
    //
    // This test intentionally runs *after* tests that mutate state and verifies
    // that setUp's resets are effective. Because XCTest does not guarantee
    // execution order, we also directly assert the post-setUp baseline here.

    @MainActor
    func testStateIsCleanAtStartOfEachTest() async throws {
        // Assert the baseline established by setUp.
        XCTAssertEqual(Application.state(\.lastTemperature).value, 0.0,
                       "lastTemperature must be 0.0 at test start (set by setUp)")
        XCTAssertEqual(Application.state(\.refreshCount).value, 0,
                       "refreshCount must be 0 at test start (set by setUp)")
        XCTAssertEqual(Application.storedState(\.lastCity).value, "",
                       "lastCity must be empty at test start (set by setUp)")

        // Now run a refresh and confirm state advances from the clean baseline.
        let token = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 5.0))
        try await WeatherService.refresh(city: "Tokyo")
        XCTAssertEqual(Application.state(\.refreshCount).value, 1)

        await token.cancel()
    }

    // MARK: - Test 6: Multiple overrides active simultaneously

    @MainActor
    func testMultipleOverridesAreActiveSimultaneously() async throws {
        // Arrange — override both dependencies at once.
        // AppState supports any number of concurrent overrides.
        let weatherToken = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 37.0))
        let clockToken   = Application.override(\.clock, with: StubClock(fixedNow: 42))

        // Act
        try await WeatherService.refresh(city: "Phoenix")

        // Assert both overrides were active together.
        XCTAssertEqual(Application.state(\.lastTemperature).value, 37.0)
        XCTAssertEqual(Application.state(\.lastRefreshTimestamp).value, 42)

        // Cancel in any order — AppState tracks each token independently.
        await clockToken.cancel()
        await weatherToken.cancel()
    }

    // MARK: - Test 7: Multiple overrides — verify ordering of cancellation

    @MainActor
    func testCancellingOneOverrideDoesNotAffectAnother() async throws {
        // Arrange — two independent overrides.
        let firstToken  = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 10.0))
        let secondToken = Application.override(\.clock, with: StubClock(fixedNow: 1_000))

        // Cancel the clock override first, leaving the provider override active.
        await secondToken.cancel()

        // Act — provider override still active, clock now restored to live SystemClock.
        try await WeatherService.refresh(city: "Seoul")

        // Assert — provider mock's value is still used…
        XCTAssertEqual(Application.state(\.lastTemperature).value, 10.0)

        // …but the timestamp now comes from the real SystemClock (not 1_000).
        let liveTimestamp = Application.state(\.lastRefreshTimestamp).value
        XCTAssertNotEqual(liveTimestamp, 1_000,
                          "After cancelling the clock override the live clock must be active")

        await firstToken.cancel()
    }

    // MARK: - Test 8: Spy captures call arguments

    @MainActor
    func testSpyProviderRecordsCityArgument() async throws {
        // SpyWeatherProvider lets us assert *how* the service called the provider,
        // not just *what it stored in state*. This is useful when the mapping
        // between input and stored value is non-trivial.
        let spy = SpyWeatherProvider(fixed: 18.0)
        let token = Application.override(\.weatherProvider, with: spy)

        try await WeatherService.refresh(city: "Madrid")
        try await WeatherService.refresh(city: "Lisbon")

        // Assert the spy recorded both cities in order.
        XCTAssertEqual(spy.callCount, 2)
        XCTAssertEqual(spy.capturedCities[0], "Madrid")
        XCTAssertEqual(spy.capturedCities[1], "Lisbon")

        // refreshCount should have bumped twice (once per successful call).
        XCTAssertEqual(Application.state(\.refreshCount).value, 2)

        await token.cancel()
    }

    // MARK: - Test 9: Monotonic clock produces increasing timestamps

    @MainActor
    func testMonotonicClockProducesStrictlyIncreasingTimestamps() async throws {
        // MonotonicClock advances by `step` on every call, so successive refreshes
        // produce timestamps 0, 1, 2, … without any real time passing.
        let clock = MonotonicClock(initial: 100, step: 50)
        let clockToken    = Application.override(\.clock, with: clock)
        let providerToken = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 0.0))

        try await WeatherService.refresh(city: "A")
        let firstTimestamp = Application.state(\.lastRefreshTimestamp).value

        try await WeatherService.refresh(city: "B")
        let secondTimestamp = Application.state(\.lastRefreshTimestamp).value

        // Each call to WeatherService.refresh reads clock.now() once.
        XCTAssertEqual(firstTimestamp, 100)
        XCTAssertEqual(secondTimestamp, 150)
        XCTAssertGreaterThan(secondTimestamp, firstTimestamp)

        await providerToken.cancel()
        await clockToken.cancel()
    }

    // MARK: - Test 10: refreshCount increments once per successful refresh

    @MainActor
    func testRefreshCountIncrementsByOnePerSuccessfulRefresh() async throws {
        let token = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 0.0))

        let refreshIterations = 5
        for index in 1...refreshIterations {
            try await WeatherService.refresh(city: "City\(index)")
            XCTAssertEqual(Application.state(\.refreshCount).value, index,
                           "refreshCount should equal the number of successful refreshes")
        }

        await token.cancel()
    }

    // MARK: - Test 11: refreshCount does NOT increment on repeated failures

    @MainActor
    func testRefreshCountNotIncrementedOnRepeatedFailures() async throws {
        let token = Application.override(\.weatherProvider, with: FailingWeatherProvider())

        for _ in 1...3 {
            do {
                try await WeatherService.refresh(city: "Nowhere")
            } catch {
                // Expected — swallow the error.
            }
        }

        XCTAssertEqual(Application.state(\.refreshCount).value, 0,
                       "refreshCount must remain 0 after three failed refreshes")

        await token.cancel()
    }

    // MARK: - Test 12: lastCity reflects the most recently refreshed city

    @MainActor
    func testLastCityUpdatesToMostRecentSuccessfulRefresh() async throws {
        let token = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 22.0))

        try await WeatherService.refresh(city: "Amsterdam")
        XCTAssertEqual(Application.storedState(\.lastCity).value, "Amsterdam")

        try await WeatherService.refresh(city: "Brussels")
        XCTAssertEqual(Application.storedState(\.lastCity).value, "Brussels",
                       "lastCity must be overwritten by the second refresh")

        await token.cancel()
    }

    // MARK: - Test 13: lastCity unchanged after a failed refresh

    @MainActor
    func testLastCityUnchangedAfterFailedRefresh() async throws {
        // First — successful refresh to set a known city.
        let successToken = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 10.0))
        try await WeatherService.refresh(city: "Vienna")
        await successToken.cancel()

        // Second — failing refresh; lastCity must stay "Vienna".
        let failToken = Application.override(\.weatherProvider, with: FailingWeatherProvider())
        do {
            try await WeatherService.refresh(city: "Nowhere")
        } catch {
            // Expected.
        }

        XCTAssertEqual(Application.storedState(\.lastCity).value, "Vienna",
                       "lastCity must not change when the refresh fails")

        await failToken.cancel()
    }
}

// MARK: - ObservationDeliveryTests (Apple only)
//
// `withObservationTracking` is available on all platforms, but reliably
// delivering the onChange callback via run-loop spin requires Foundation's
// async scheduling, which behaves differently on Linux. These tests are
// therefore gated to Apple platforms where the behaviour is well-defined.

#if !os(Linux) && !os(Windows)

// MARK: - SendableBox
//
// A generic, lock-guarded mutable container for use inside @Sendable closures.
// `onChange` closures in `withObservationTracking` must be @Sendable, which
// means they cannot capture `var` values from the enclosing scope.
// `SendableBox` bridges that gap safely.

private final class SendableBox<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Value

    var value: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }

    init(_ initial: Value) {
        self._value = initial
    }
}

// MARK: - ObservationDeliveryTests

final class ObservationDeliveryTests: XCTestCase {

    // Reset state before each test.
    @MainActor
    override func setUp() async throws {
        // NOTE: No super.setUp() call — see the comment in WeatherServiceTests.setUp.
        var temperature = Application.state(\.lastTemperature)
        temperature.value = 0.0

        var count = Application.state(\.refreshCount)
        count.value = 0

        var timestamp = Application.state(\.lastRefreshTimestamp)
        timestamp.value = 0

        var city = Application.storedState(\.lastCity)
        city.value = ""
    }

    // MARK: - Test 1: onChange fires when lastTemperature changes
    //
    // PATTERN: arm withObservationTracking before the mutation, then mutate,
    // then yield to let the onChange callback execute.

    @MainActor
    func testOnChangeFiresWhenTemperatureChanges() async throws {
        // Arrange — capture onChange delivery in a thread-safe box.
        let didFire = SendableBox(false)

        withObservationTracking {
            _ = Application.state(\.lastTemperature).value
        } onChange: { [didFire] in
            didFire.value = true
        }

        // Act — override and refresh to mutate lastTemperature.
        let token = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 55.0))
        try await WeatherService.refresh(city: "Cairo")

        // Yield to the run loop so the onChange closure can execute.
        await Task.yield()

        // Assert
        XCTAssertTrue(didFire.value, "onChange must fire after lastTemperature is mutated")
        await token.cancel()
    }

    // MARK: - Test 2: onChange is one-shot — does not fire a second time

    @MainActor
    func testOnChangeIsSingleShotWithoutRearming() async throws {
        let fireCount = SendableBox(0)

        withObservationTracking {
            _ = Application.state(\.lastTemperature).value
        } onChange: { [fireCount] in
            fireCount.value += 1
        }

        let token = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 10.0))

        // Two successive refreshes — onChange should fire only once.
        try await WeatherService.refresh(city: "Athens")
        await Task.yield()
        try await WeatherService.refresh(city: "Athens")
        await Task.yield()

        XCTAssertEqual(fireCount.value, 1,
                       "One-shot onChange must not fire again without re-arming")

        await token.cancel()
    }

    // MARK: - Test 3: Re-armed observation captures consecutive mutations

    @MainActor
    func testRearmingCapturesConsecutiveMutations() async throws {
        let temperatures = SendableBox<[Double]>([])
        let expectedCount = 3

        // Encapsulate the re-arming logic so the closure can capture `self`
        // as @Sendable without capturing mutable local state.
        final class Observer: @unchecked Sendable {
            private let collected: SendableBox<[Double]>
            private let target: Int

            init(collected: SendableBox<[Double]>, target: Int) {
                self.collected = collected
                self.target = target
            }

            @MainActor
            func arm() {
                withObservationTracking {
                    _ = Application.state(\.lastTemperature).value
                } onChange: { [self] in
                    Task { @MainActor in
                        let current = Application.state(\.lastTemperature).value
                        var all = self.collected.value
                        all.append(current)
                        self.collected.value = all
                        if all.count < self.target {
                            self.arm()
                        }
                    }
                }
            }
        }

        let observer = Observer(collected: temperatures, target: expectedCount)
        observer.arm()

        let token = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 0.0))

        // Perform three refreshes with distinct temperatures.
        for degree in [1.0, 2.0, 3.0] {
            let stepToken = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: degree))
            try await WeatherService.refresh(city: "Test")
            await stepToken.cancel()
            await Task.yield()
            await Task.yield()
        }

        // Allow pending Task closures to complete.
        for _ in 0..<10 {
            await Task.yield()
        }

        XCTAssertEqual(temperatures.value.count, expectedCount,
                       "Re-armed observer must capture all \(expectedCount) mutations")

        await token.cancel()
    }
}

#endif // !os(Linux) && !os(Windows)
