import Foundation

// MARK: - MockWeatherProvider

/// A `WeatherProviding` stub that always returns a fixed temperature.
///
/// Use this in tests when you want the provider to succeed with a known value:
/// ```swift
/// let token = Application.override(\.weatherProvider, with: MockWeatherProvider(fixed: 21.0))
/// defer { Task { await token.cancel() } }
/// ```
public struct MockWeatherProvider: WeatherProviding {
    /// The temperature that will always be returned, regardless of the city argument.
    public let fixedTemperature: Double

    /// Creates a mock provider that always reports `fixedTemperature`.
    public init(fixed fixedTemperature: Double) {
        self.fixedTemperature = fixedTemperature
    }

    public func currentTemperature(for city: String) async throws -> Double {
        fixedTemperature
    }
}

// MARK: - FailingWeatherProvider

/// A `WeatherProviding` stub that always throws `WeatherError.unavailable`.
///
/// Use this to exercise error-handling code paths:
/// ```swift
/// let token = Application.override(\.weatherProvider, with: FailingWeatherProvider(reason: "no network"))
/// ```
public struct FailingWeatherProvider: WeatherProviding {
    /// A human-readable reason embedded in the thrown error.
    public let reason: String

    /// Creates a failing provider that embeds `reason` in its error.
    public init(reason: String = "simulated failure") {
        self.reason = reason
    }

    public func currentTemperature(for city: String) async throws -> Double {
        throw WeatherError.unavailable(reason)
    }
}

// MARK: - SpyWeatherProvider

/// A `WeatherProviding` stub that records each city argument it receives.
///
/// Because `SpyWeatherProvider` accumulates mutable state across concurrency
/// boundaries it uses `NSLock` for thread safety and adopts `@unchecked Sendable`.
///
/// ```swift
/// let spy = SpyWeatherProvider(fixed: 15.0)
/// let token = Application.override(\.weatherProvider, with: spy)
/// try await WeatherService.refresh(city: "Tokyo")
/// XCTAssertEqual(spy.capturedCities, ["Tokyo"])
/// await token.cancel()
/// ```
public final class SpyWeatherProvider: WeatherProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var _capturedCities: [String] = []

    /// The fixed temperature returned for every call (regardless of city).
    public let fixedTemperature: Double

    /// All city arguments received, in order of invocation.
    public var capturedCities: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _capturedCities
    }

    /// How many times `currentTemperature(for:)` was called.
    public var callCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _capturedCities.count
    }

    /// Creates a spy that returns `fixedTemperature` on every call.
    public init(fixed fixedTemperature: Double) {
        self.fixedTemperature = fixedTemperature
    }

    public func currentTemperature(for city: String) async throws -> Double {
        // `withLock` is the async-safe locking primitive in Swift 5.10+;
        // plain `lock()` / `unlock()` are unavailable from async contexts under
        // strict concurrency checking.
        lock.withLock { _capturedCities.append(city) }
        return fixedTemperature
    }
}

// MARK: - StubClock

/// A `Clock` implementation that always returns a pinned epoch-second value.
///
/// Pinning time makes temporal assertions deterministic:
/// ```swift
/// let token = Application.override(\.clock, with: StubClock(fixedNow: 1_000_000))
/// try await WeatherService.refresh(city: "Oslo")
/// XCTAssertEqual(Application.state(\.lastRefreshTimestamp).value, 1_000_000)
/// await token.cancel()
/// ```
public struct StubClock: Clock {
    /// The value returned by every `now()` call.
    public let fixedNow: Int

    /// Creates a stub clock pinned to `fixedNow` epoch seconds.
    public init(fixedNow: Int) {
        self.fixedNow = fixedNow
    }

    public func now() -> Int { fixedNow }
}

// MARK: - MonotonicClock

/// A `Clock` whose value advances by `step` seconds on each `now()` call.
///
/// Useful for tests that need to observe *increasing* timestamps across
/// multiple refreshes without actually waiting for wall-clock time to pass.
public final class MonotonicClock: Clock, @unchecked Sendable {
    private let lock = NSLock()
    private var _current: Int
    private let step: Int

    /// Creates a clock that starts at `initial` and advances by `step` each call.
    public init(initial: Int = 0, step: Int = 1) {
        self._current = initial
        self.step = step
    }

    public func now() -> Int {
        lock.lock()
        defer {
            _current += step
            lock.unlock()
        }
        return _current
    }
}
