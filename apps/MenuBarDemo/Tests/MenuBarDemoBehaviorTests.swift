import XCTest
import AppState
@testable import MenuBarDemo

// MARK: - Menu Bar Behavior Tests

/// Fast behavioral coverage for services and each AppState 3 application accessor.
@MainActor
internal final class MenuBarDemoBehaviorTests: XCTestCase {
    internal func testGreetingServicesHandleNamedAndEmptyValues() {
        let live = LiveGreetingService()
        let mock = MockGreetingService()

        XCTAssertEqual(live.compose(from: "Ship it"), "✦ Ship it")
        XCTAssertEqual(live.compose(from: ""), "Hello, AppState!")
        XCTAssertEqual(mock.compose(from: "Ship it"), "[MOCK] Ship it")
        XCTAssertEqual(mock.compose(from: ""), "[MOCK] No greeting set")
    }

    internal func testStateAndStoredStateRoundTripValues() {
        var count = Application.state(\.clickCount)
        count.value = 7
        XCTAssertEqual(Application.state(\.clickCount).value, 7)

        var greeting = Application.storedState(\.greeting)
        greeting.value = "Verified"
        XCTAssertEqual(Application.storedState(\.greeting).value, "Verified")
    }

    internal func testSyncStateAccessorRoundTripsValue() {
        var accent = Application.syncState(\.accentName)
        accent.value = "Purple"
        XCTAssertEqual(Application.syncState(\.accentName).value, "Purple")
    }

    internal func testDependencyOverrideRestoresLiveService() async {
        XCTAssertTrue(Application.dependency(\.greetingService) is LiveGreetingService)
        let override = Application.override(\.greetingService, with: MockGreetingService())
        XCTAssertTrue(Application.dependency(\.greetingService) is MockGreetingService)
        await override.cancel()
        XCTAssertTrue(Application.dependency(\.greetingService) is LiveGreetingService)
    }
}
