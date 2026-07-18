import XCTest

// MARK: - Visual Evidence UI Tests

/// Captures the ordered frames used by the repository's SwiftUI proof GIF.
internal final class VisualEvidenceUITests: SwiftUIDemoUITestCase {
    internal func testCaptureAppStateTour() throws {
        XCTAssertTrue(app.navigationBars["State"].waitForExistence(timeout: 5))
        captureSnapshot(named: "01-state-catalog")

        app.tabBars.buttons["Workflow"].tap()
        XCTAssertTrue(app.navigationBars["Delivery Workflow"].waitForExistence(timeout: 5))
        captureSnapshot(named: "02-workflow-initial")

        app.buttons["WorkflowTask-map"].tap()
        app.buttons["WorkflowTask-state"].tap()
        XCTAssertEqual(app.staticTexts["WorkflowProgressCount"].label, "2/5")
        captureSnapshot(named: "03-workflow-progress")

        app.buttons["AnalyzeWorkflowButton"].tap()
        XCTAssertTrue(app.staticTexts["WorkflowRecommendationHeadline"].waitForExistence(timeout: 5))
        captureSnapshot(named: "04-workflow-analysis")

        app.tabBars.buttons["Observability"].tap()
        XCTAssertTrue(app.staticTexts["ObserverStatus"].waitForExistence(timeout: 5))
        app.buttons["ObservabilityCounterStepper-Increment"].tap()
        XCTAssertTrue(app.staticTexts["ObserverLogEntry"].waitForExistence(timeout: 5))
        captureSnapshot(named: "05-observability")
    }
}
