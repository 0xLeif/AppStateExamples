import XCTest

// MARK: - Observability UI Tests

/// XCUITest flows that verify the headless observation log updates
/// when the counter is toggled from the Observability tab.
final class ObservabilityUITests: XCTestCase {

    // MARK: Properties

    private var app: XCUIApplication!

    // MARK: Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    // MARK: Tests

    /// Navigates to the Observability tab, increments the counter, and asserts
    /// that the headless observer's event count increases.
    func testObserverLogsCounterChange() throws {
        // Navigate to the Observability tab.
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Observability"].tap()

        // Wait for the observer to appear and confirm it is active.
        let statusLabel = app.staticTexts["ObserverStatus"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5), "Observer status label should appear")
        XCTAssertEqual(statusLabel.label, "Observing", "Observer should be active on appear")

        // Read the initial event count.
        let eventCountLabel = app.staticTexts["ObserverEventCount"]
        XCTAssertTrue(eventCountLabel.waitForExistence(timeout: 5))
        let initialCountText = eventCountLabel.label
        let initialCount = Int(initialCountText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0

        // Increment the counter three times via the stepper.
        let stepper = app.steppers["ObservabilityCounterStepper"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 5), "Counter stepper should appear")

        for _ in 0..<3 {
            stepper.buttons["Increment"].tap()
        }

        // Wait a moment for the async re-arm cycle to complete.
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { [weak self] _, _ in
                guard let self else { return false }
                let currentText = self.app.staticTexts["ObserverEventCount"].label
                let currentCount = Int(currentText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
                return currentCount >= initialCount + 3
            },
            object: nil
        )
        wait(for: [expectation], timeout: 5)

        // Assert at least 3 new events were logged.
        let finalCountText = app.staticTexts["ObserverEventCount"].label
        let finalCount = Int(finalCountText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
        XCTAssertGreaterThanOrEqual(
            finalCount,
            initialCount + 3,
            "Headless observer should log at least one event per counter increment"
        )

        // Assert log entries are visible.
        let firstEntry = app.staticTexts.matching(identifier: "ObserverLogEntry").firstMatch
        XCTAssertTrue(firstEntry.exists, "At least one log entry should appear in the Change Log section")
    }

    /// Toggles the observer off and confirms the event count stops increasing.
    func testStopObserverPreventsNewLogs() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["Observability"].tap()

        // Wait for observer to be active.
        let statusLabel = app.staticTexts["ObserverStatus"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5))
        XCTAssertEqual(statusLabel.label, "Observing")

        // Stop the observer.
        let toggleButton = app.buttons["ToggleObserverButton"]
        XCTAssertTrue(toggleButton.waitForExistence(timeout: 5))
        toggleButton.tap()

        // Confirm it stopped.
        XCTAssertEqual(statusLabel.label, "Stopped", "Observer status should change to Stopped")

        // Record event count after stopping.
        let eventCountLabel = app.staticTexts["ObserverEventCount"]
        let countAfterStop = eventCountLabel.label

        // Increment the counter.
        let stepper = app.steppers["ObservabilityCounterStepper"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        stepper.buttons["Increment"].tap()
        stepper.buttons["Increment"].tap()

        // Event count should remain the same since observer is stopped.
        XCTAssertEqual(
            eventCountLabel.label,
            countAfterStop,
            "Event count should not increase when observer is stopped"
        )
    }
}
