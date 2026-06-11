# Testing with AppState 3.0 — Showcase

A focused, production-quality example package that teaches every testing
pattern available in AppState 3.0. **The tests are the product**: each test
method is heavily commented so you can learn the patterns just by reading them.

## What you will learn

| Pattern | Test method(s) |
|---|---|
| Override a dependency with a mock | `testOverridingWeatherProviderWithMockProducesExpectedTemperature` |
| Cancelling an override restores the live dependency | `testCancellingOverrideRestoresLiveProvider` |
| Inject a controllable clock | `testStubClockProducesDeterministicTimestamp` |
| Testing error paths (state unchanged on failure) | `testFailingProviderDoesNotMutateState`, `testLastCityUnchangedAfterFailedRefresh`, `testRefreshCountNotIncrementedOnRepeatedFailures` |
| State isolation between tests | `testStateIsCleanAtStartOfEachTest` |
| Multiple simultaneous overrides | `testMultipleOverridesAreActiveSimultaneously` |
| Cancel one override without disturbing another | `testCancellingOneOverrideDoesNotAffectAnother` |
| Spy / call-argument recording | `testSpyProviderRecordsCityArgument` |
| Monotonic (ever-advancing) time | `testMonotonicClockProducesStrictlyIncreasingTimestamps` |
| Increment / no-increment invariants | `testRefreshCountIncrementsByOnePerSuccessfulRefresh` |
| (Apple only) observation-delivery assertion | `testOnChangeFiresWhenTemperatureChanges`, `testOnChangeIsSingleShotWithoutRearming`, `testRearmingCapturesConsecutiveMutations` |

---

## Core patterns

### 1. The override mechanism

`Application.override(_:with:)` swaps a registered dependency for any value
that satisfies the same type. It returns an `Application.DependencyOverride`
token that you **must** cancel when the test is done:

```swift
let token = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 21.0))
try await WeatherService.refresh(city: "London")
XCTAssertEqual(Application.state(\.lastTemperature).value, 21.0)
await token.cancel()   // <-- restore the live dependency; await is required
```

`cancel()` is `async` — it waits for AppState's internal actor to complete the
restoration before returning. Always `await` it so the next test starts clean.

### 2. Mocking dependencies

Implement the protocol and inject it via override:

```swift
struct MockWeatherProvider: WeatherProviding {
    let fixedTemperature: Double
    func currentTemperature(for city: String) async throws -> Double {
        fixedTemperature
    }
}
```

The `MockWeatherProvider`, `FailingWeatherProvider`, `SpyWeatherProvider`,
`StubClock`, and `MonotonicClock` test doubles live in `Sources/TestingShowcase/TestDoubles.swift`
so adopters can import them directly.

### 3. Controlling time

Inject a `StubClock` to pin time to an exact epoch-second value:

```swift
let token = Application.override(\.clock, with: StubClock(fixedNow: 1_700_000_000))
try await WeatherService.refresh(city: "Oslo")
XCTAssertEqual(Application.state(\.lastRefreshTimestamp).value, 1_700_000_000)
await token.cancel()
```

Use `MonotonicClock` when you need timestamps to advance across multiple calls
without waiting for real time.

### 4. Isolating state between tests

Reset **all** scalar state in `setUp`. The critical rules:

- Bind to a `var` before assigning — `Application.state(\.x).value = y` does
  **not** compile because `state(_:)` returns a temporary value type.
- Do **not** call `super.setUp()` — in Swift 6.1 with strict concurrency, the
  base `XCTestCase.setUp()` is not `@MainActor`-annotated, which causes a
  compiler error on Linux.

```swift
@MainActor
override func setUp() async throws {
    // NOT: super.setUp()  <-- omit this

    var temperature = Application.state(\.lastTemperature)
    temperature.value = 0.0

    var count = Application.state(\.refreshCount)
    count.value = 0
}
```

### 5. Multiple overrides

Hold tokens for both overrides simultaneously; cancel them in any order:

```swift
let weatherToken = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 37.0))
let clockToken   = Application.override(\.clock, with: StubClock(fixedNow: 42))
// … exercise code …
await clockToken.cancel()
await weatherToken.cancel()
```

### 6. Observation delivery (Apple only)

`withObservationTracking` fires its `onChange` closure once when any tracked
state changes. Re-arm inside `onChange` to keep observing. Gate these tests
with `#if !os(Linux) && !os(Windows)`.

`onChange` must be `@Sendable`, so use `SendableBox` (a lock-guarded wrapper)
to capture mutable state across the concurrency boundary:

```swift
private final class SendableBox<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Value
    var value: Value {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
    init(_ initial: Value) { self._value = initial }
}
```

---

## Package structure

```
testing-showcase/
├── Package.swift
├── README.md
├── Sources/TestingShowcase/
│   ├── WeatherProviding.swift          # Protocol + LiveWeatherProvider
│   ├── Clock.swift                     # Protocol + SystemClock
│   ├── Application+WeatherState.swift  # State & dependency registrations
│   ├── WeatherService.swift            # The unit under test (@MainActor enum)
│   └── TestDoubles.swift               # Public mocks/stubs for reuse
└── Tests/TestingShowcaseTests/
    └── WeatherServiceTests.swift       # 16 documented test methods
```

## Running the tests

```sh
cd packages/testing-showcase
swift test
```

Expected output: **16 tests, 0 failures**.

## Platform notes

- All 13 `WeatherServiceTests` methods are cross-platform (macOS + Linux).
- The 3 `ObservationDeliveryTests` methods are Apple-only, gated with
  `#if !os(Linux) && !os(Windows)`.
- All state is scalar (`Double`, `Int`, `String`) — no arrays or dictionaries,
  which avoids a known Linux crash in AppState 3.0-rc.1.
