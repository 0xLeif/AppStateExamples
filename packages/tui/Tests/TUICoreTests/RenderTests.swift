import XCTest
import AppState
@testable import TUICore

// MARK: - RenderTests

/// Verifies that `DashboardController.render()` produces frames containing
/// expected substrings for various state configurations.
final class RenderTests: XCTestCase {

    // MARK: - Setup

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

    // MARK: - Structure

    @MainActor
    func testRenderContainsDashboardLabel() {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("AppState Live Dashboard"))
    }

    @MainActor
    func testRenderContainsCounterRow() {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("Counter"))
    }

    @MainActor
    func testRenderContainsTemperatureRow() {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("Temp"))
    }

    @MainActor
    func testRenderContainsGaugeRow() {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("Gauge"))
    }

    @MainActor
    func testRenderContainsStatusRow() {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("Status"))
    }

    @MainActor
    func testRenderContainsHelpKeys() {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("[i]"))
        XCTAssertTrue(frame.contains("[d]"))
        XCTAssertTrue(frame.contains("[w]"))
        XCTAssertTrue(frame.contains("[c]"))
        XCTAssertTrue(frame.contains("[p]"))
        XCTAssertTrue(frame.contains("[r]"))
        XCTAssertTrue(frame.contains("[q]"))
    }

    // MARK: - Counter Values

    @MainActor
    func testRenderShowsCorrectCounterValue() {
        DashboardController.apply(.increment)
        DashboardController.apply(.increment)
        DashboardController.apply(.increment)
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("3"))
    }

    @MainActor
    func testRenderShowsNegativeCounter() {
        DashboardController.apply(.decrement)
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("-1"))
    }

    // MARK: - Temperature Values

    @MainActor
    func testRenderShowsTemperatureAfterWarmer() {
        DashboardController.apply(.warmer)
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("25.0"))
    }

    @MainActor
    func testRenderShowsTemperatureAfterCooler() {
        DashboardController.apply(.cooler)
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("15.0"))
    }

    // MARK: - Status

    @MainActor
    func testRenderShowsRunningStatusByDefault() {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("RUNNING"))
    }

    @MainActor
    func testRenderShowsPausedStatusWhenPaused() {
        DashboardController.apply(.togglePause)
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("PAUSED"))
    }

    @MainActor
    func testRenderShowsRunningStatusAfterUnpause() {
        DashboardController.apply(.togglePause)
        DashboardController.apply(.togglePause)
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("RUNNING"))
    }

    // MARK: - Multiline Output

    @MainActor
    func testRenderProducesMultipleLines() {
        let frame = DashboardController.render()
        let lineCount = frame.components(separatedBy: "\n").count
        XCTAssertGreaterThan(lineCount, 8, "Dashboard should have more than 8 lines")
    }
}
