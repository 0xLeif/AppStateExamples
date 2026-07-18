import XCTest

// MARK: - Feature Catalog UI Tests

/// End-to-end journeys across the integrated state and dependency examples.
internal final class FeatureCatalogUITests: SwiftUIDemoUITestCase {
    internal func testWorkflowCoordinatesStatePersistenceAndDependency() throws {
        app.tabBars.buttons["Workflow"].tap()

        let progress = app.staticTexts["WorkflowProgressCount"]
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        XCTAssertEqual(progress.label, "0/5")

        app.buttons["WorkflowTask-map"].tap()
        XCTAssertEqual(progress.label, "1/5")
        XCTAssertEqual(app.staticTexts["WorkflowEventCount"].label, "1 activity events")

        let recommendation = app.staticTexts["WorkflowRecommendationHeadline"]
        app.buttons["AnalyzeWorkflowButton"].tap()
        XCTAssertTrue(recommendation.waitForExistence(timeout: 5))
        XCTAssertEqual(recommendation.label, "Next: Build")

        let automationToggle = app.switches["WorkflowAutomationToggle"]
        XCTAssertTrue(automationToggle.exists)
        tapSwitch(automationToggle)

        app.buttons["WorkflowTask-state"].tap()
        XCTAssertEqual(progress.label, "2/5")

        let verifyRecommendation = NSPredicate(format: "label == 'Next: Verify'")
        expectation(for: verifyRecommendation, evaluatedWith: recommendation)
        waitForExpectations(timeout: 5)

        app.buttons["ResetWorkflowButton"].tap()
        XCTAssertEqual(progress.label, "0/5")
        XCTAssertEqual(app.staticTexts["WorkflowEventCount"].label, "0 activity events")
    }

    internal func testCounterAndDependencyOverrideJourney() throws {
        app.buttons["CounterNavLink"].tap()

        let counter = app.staticTexts["CounterValue"]
        XCTAssertTrue(counter.waitForExistence(timeout: 5))
        app.buttons["CounterStepper-Increment"].tap()
        XCTAssertEqual(counter.label, "1")
        app.buttons["ResetCounterButton"].tap()
        XCTAssertEqual(counter.label, "0")

        app.tabBars.buttons["Dependencies"].tap()
        app.staticTexts["Greeting Service"].tap()

        let activeService = app.staticTexts["ActiveServiceLabel"]
        XCTAssertTrue(activeService.waitForExistence(timeout: 5))
        app.buttons["SwapToMockButton"].tap()
        XCTAssertEqual(activeService.label, "Service, MockGreetingService")
        app.buttons["RestoreLiveButton"].tap()
        waitForLabel(of: activeService, containing: "LiveGreetingService")
    }
}
