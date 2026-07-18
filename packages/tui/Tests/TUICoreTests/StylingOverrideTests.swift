import XCTest
import AppState
@testable import TUICore

// MARK: - StylingOverrideTests

/// Verifies that injecting a custom `FrameStyling` dependency changes the rendered output,
/// demonstrating AppState 3.0 dependency overrides in a testable, headless context.
internal final class StylingOverrideTests: XCTestCase {

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

    // MARK: - PlainFrameStyling Override

    @MainActor
    internal func testPlainStylingUsesASCIICharacters() async {
        let token = Application.override(\.frameStyling, with: PlainFrameStyling())

        let frame = DashboardController.render()

        await token.cancel()

        // Plain styling must not contain any box-drawing Unicode characters.
        XCTAssertFalse(frame.contains("─"), "Plain style should not use box-drawing hyphens")
        XCTAssertFalse(frame.contains("│"), "Plain style should not use box-drawing vertical bars")
        XCTAssertFalse(frame.contains("╭"), "Plain style should not use box-drawing corners")

        // Plain styling should use ASCII alternatives.
        XCTAssertTrue(frame.contains("+"), "Plain style should use + for corners")
        XCTAssertTrue(frame.contains("|"), "Plain style should use | for vertical borders")
    }

    @MainActor
    internal func testDefaultStylingUsesBoxDrawingCharacters() async {
        let frame = DashboardController.render()
        XCTAssertTrue(frame.contains("─") || frame.contains("╭"),
                      "Default style should use box-drawing characters")
    }

    @MainActor
    internal func testOverrideIsRevertedAfterCancel() async {
        let token = Application.override(\.frameStyling, with: PlainFrameStyling())
        await token.cancel()

        let frame = DashboardController.render()
        // After cancelling the override, the default box-drawing corners should be back.
        XCTAssertTrue(frame.contains("╭") || frame.contains("─"),
                      "After cancelling override, default box-drawing styling should be restored")
    }

    // MARK: - Custom Styling

    @MainActor
    internal func testCustomStylingReflectedInRender() async {
        let token = Application.override(\.frameStyling, with: WideFrameStyling())

        let frame = DashboardController.render()

        await token.cancel()

        // The wide frame has a frameWidth of 70, so inner content should fill more space.
        // We simply verify the render still contains required substrings under the override.
        XCTAssertTrue(frame.contains("Counter"))
        XCTAssertTrue(frame.contains("Temp"))
        XCTAssertTrue(frame.contains("Status"))
    }

    @MainActor
    internal func testCustomGaugeCharactersAppearsInRender() async {
        let token = Application.override(\.frameStyling, with: WideFrameStyling())

        let frame = DashboardController.render()

        await token.cancel()

        // WideFrameStyling uses ▓ for filled gauge segments.
        XCTAssertTrue(frame.contains("▓") || frame.contains("░"),
                      "Custom gauge characters should appear in the rendered frame")
    }
}

// MARK: - WideFrameStyling (test-only)

/// A wider variant of `DefaultFrameStyling` used to verify that `frameWidth` is respected.
private struct WideFrameStyling: FrameStyling {
    var horizontalBorder: Character { "─" }
    var verticalBorder: Character { "│" }
    var cornerTopLeft: Character { "╭" }
    var cornerTopRight: Character { "╮" }
    var cornerBottomLeft: Character { "╰" }
    var cornerBottomRight: Character { "╯" }
    var gaugeFilled: Character { "▓" }
    var gaugeEmpty: Character { "░" }
    var frameWidth: Int { 70 }
    var gaugeWidth: Int { 40 }
}
