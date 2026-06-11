import XCTest
import AppState
@testable import TUICore

// MARK: - DashboardCommandTests

/// Verifies that each `DashboardCommand` mutates exactly the expected scalar state.
final class DashboardCommandTests: XCTestCase {

    // MARK: - Setup

    /// Resets all dashboard state before each test.
    /// Note: do NOT call `super.setUp()` — it triggers a concurrency assertion in Swift 6.1 on Linux.
    @MainActor
    override func setUp() async throws {
        var counter = Application.state(\.counter)
        counter.value = 0
        var temperature = Application.state(\.temperature)
        temperature.value = 20.0
        var paused = Application.state(\.paused)
        paused.value = false
        var label = Application.storedState(\.dashboardLabel)
        label.value = "AppState Live Dashboard"
    }

    // MARK: - increment

    @MainActor
    func testIncrementIncreasesCounterByOne() {
        DashboardController.apply(.increment)
        XCTAssertEqual(Application.state(\.counter).value, 1)
    }

    @MainActor
    func testIncrementMultipleTimes() {
        DashboardController.apply(.increment)
        DashboardController.apply(.increment)
        DashboardController.apply(.increment)
        XCTAssertEqual(Application.state(\.counter).value, 3)
    }

    @MainActor
    func testIncrementDoesNotChangeTemperatureOrPause() {
        DashboardController.apply(.increment)
        XCTAssertEqual(Application.state(\.temperature).value, 20.0)
        XCTAssertFalse(Application.state(\.paused).value)
    }

    // MARK: - decrement

    @MainActor
    func testDecrementDecreasesCounterByOne() {
        DashboardController.apply(.decrement)
        XCTAssertEqual(Application.state(\.counter).value, -1)
    }

    @MainActor
    func testDecrementFromPositive() {
        DashboardController.apply(.increment)
        DashboardController.apply(.increment)
        DashboardController.apply(.decrement)
        XCTAssertEqual(Application.state(\.counter).value, 1)
    }

    @MainActor
    func testDecrementDoesNotChangeTemperatureOrPause() {
        DashboardController.apply(.decrement)
        XCTAssertEqual(Application.state(\.temperature).value, 20.0)
        XCTAssertFalse(Application.state(\.paused).value)
    }

    // MARK: - warmer

    @MainActor
    func testWarmerIncreasesTemperatureByFive() {
        DashboardController.apply(.warmer)
        XCTAssertEqual(Application.state(\.temperature).value, 25.0, accuracy: 0.001)
    }

    @MainActor
    func testWarmerClampsAtMaximum() {
        // Push temperature well past the maximum.
        for _ in 0..<30 {
            DashboardController.apply(.warmer)
        }
        XCTAssertEqual(
            Application.state(\.temperature).value,
            DashboardController.maximumTemperature,
            accuracy: 0.001
        )
    }

    @MainActor
    func testWarmerDoesNotChangeCounter() {
        DashboardController.apply(.warmer)
        XCTAssertEqual(Application.state(\.counter).value, 0)
    }

    // MARK: - cooler

    @MainActor
    func testCoolerDecreasesTemperatureByFive() {
        DashboardController.apply(.cooler)
        XCTAssertEqual(Application.state(\.temperature).value, 15.0, accuracy: 0.001)
    }

    @MainActor
    func testCoolerClampsAtMinimum() {
        // Push temperature well past the minimum.
        for _ in 0..<30 {
            DashboardController.apply(.cooler)
        }
        XCTAssertEqual(
            Application.state(\.temperature).value,
            DashboardController.minimumTemperature,
            accuracy: 0.001
        )
    }

    @MainActor
    func testCoolerDoesNotChangeCounter() {
        DashboardController.apply(.cooler)
        XCTAssertEqual(Application.state(\.counter).value, 0)
    }

    // MARK: - togglePause

    @MainActor
    func testTogglePauseFlipsFalseToTrue() {
        DashboardController.apply(.togglePause)
        XCTAssertTrue(Application.state(\.paused).value)
    }

    @MainActor
    func testTogglePauseFlipsTrueToFalse() {
        DashboardController.apply(.togglePause)
        DashboardController.apply(.togglePause)
        XCTAssertFalse(Application.state(\.paused).value)
    }

    @MainActor
    func testTogglePauseDoesNotChangeCounterOrTemperature() {
        DashboardController.apply(.togglePause)
        XCTAssertEqual(Application.state(\.counter).value, 0)
        XCTAssertEqual(Application.state(\.temperature).value, 20.0, accuracy: 0.001)
    }

    // MARK: - reset

    @MainActor
    func testResetRestoresAllStateToDefaults() {
        DashboardController.apply(.increment)
        DashboardController.apply(.increment)
        DashboardController.apply(.warmer)
        DashboardController.apply(.togglePause)

        DashboardController.apply(.reset)

        XCTAssertEqual(Application.state(\.counter).value, 0)
        XCTAssertEqual(Application.state(\.temperature).value, 20.0, accuracy: 0.001)
        XCTAssertFalse(Application.state(\.paused).value)
    }

    // MARK: - quit

    @MainActor
    func testQuitReturnsFalse() {
        let shouldContinue = DashboardController.apply(.quit)
        XCTAssertFalse(shouldContinue)
    }

    @MainActor
    func testNonQuitCommandReturnsTrue() {
        let shouldContinue = DashboardController.apply(.increment)
        XCTAssertTrue(shouldContinue)
    }

    // MARK: - Key Mapping

    func testKeyMappingCoversAllNonQuitCommands() {
        XCTAssertEqual(DashboardCommand.from(key: "i"), .increment)
        XCTAssertEqual(DashboardCommand.from(key: "d"), .decrement)
        XCTAssertEqual(DashboardCommand.from(key: "w"), .warmer)
        XCTAssertEqual(DashboardCommand.from(key: "c"), .cooler)
        XCTAssertEqual(DashboardCommand.from(key: "p"), .togglePause)
        XCTAssertEqual(DashboardCommand.from(key: "r"), .reset)
        XCTAssertEqual(DashboardCommand.from(key: "q"), .quit)
    }

    func testUnrecognisedKeyReturnsNil() {
        XCTAssertNil(DashboardCommand.from(key: "x"))
        XCTAssertNil(DashboardCommand.from(key: "z"))
        XCTAssertNil(DashboardCommand.from(key: " "))
    }
}
