import XCTest
import AppState
@testable import TUICore

// MARK: - RenderTests

/// Verifies that `DashboardController.render()` produces frames containing
/// expected substrings for various state configurations.
internal final class RenderTests: XCTestCase {

    // MARK: - Setup

    @MainActor
    internal override func setUp() async throws {
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
    internal func testRenderContainsDashboardLabel() async {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("AppState Live Dashboard"))
    }

    @MainActor
    internal func testRenderContainsCounterRow() async {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("Counter"))
    }

    @MainActor
    internal func testRenderContainsTemperatureRow() async {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("Temp"))
    }

    @MainActor
    internal func testRenderContainsGaugeRow() async {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("Gauge"))
    }

    @MainActor
    internal func testRenderContainsStatusRow() async {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("Status"))
    }

    @MainActor
    internal func testRenderContainsHelpKeys() async {
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
    internal func testRenderShowsCorrectCounterValue() async {
        DashboardController.apply(.increment)
        DashboardController.apply(.increment)
        DashboardController.apply(.increment)
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("3"))
    }

    @MainActor
    internal func testRenderShowsNegativeCounter() async {
        DashboardController.apply(.decrement)
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("-1"))
    }

    // MARK: - Temperature Values

    @MainActor
    internal func testRenderShowsTemperatureAfterWarmer() async {
        DashboardController.apply(.warmer)
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("25.0"))
    }

    @MainActor
    internal func testRenderShowsTemperatureAfterCooler() async {
        DashboardController.apply(.cooler)
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("15.0"))
    }

    // MARK: - Status

    @MainActor
    internal func testRenderShowsRunningStatusByDefault() async {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("RUNNING"))
    }

    @MainActor
    internal func testRenderShowsPausedStatusWhenPaused() async {
        DashboardController.apply(.togglePause)
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("PAUSED"))
    }

    @MainActor
    internal func testRenderShowsRunningStatusAfterUnpause() async {
        DashboardController.apply(.togglePause)
        DashboardController.apply(.togglePause)
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("RUNNING"))
    }

    // MARK: - Multiline Output

    @MainActor
    internal func testRenderProducesMultipleLines() async {
        let frame = DashboardController.render()
        let lineCount = frame.components(separatedBy: "\n").count
        XCTAssertGreaterThan(lineCount, 8, "Dashboard should have more than 8 lines")
    }
}
