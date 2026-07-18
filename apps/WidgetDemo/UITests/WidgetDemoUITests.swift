import XCTest

// MARK: - Widget Demo UI Tests

/// End-to-end proof that edits persist and both actions update the shared AppState values.
@MainActor
internal final class WidgetDemoUITests: XCTestCase {
    internal func testEditIncrementPersistAndResetJourney() {
        let app = XCUIApplication()
        app.launchArguments = ["-ResetDemoState"]
        app.launch()

        let titleField = app.textFields["FocusTitleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        replaceText(in: titleField, with: "Deep Work")

        app.buttons["IncrementButton"].tap()
        app.buttons["IncrementButton"].tap()
        XCTAssertEqual(app.staticTexts["FocusCountValue"].label, "Completed Increments, 2")

        app.terminate()
        app.launchArguments = []
        app.launch()

        XCTAssertEqual(app.textFields["FocusTitleField"].value as? String, "Deep Work")
        XCTAssertEqual(app.staticTexts["FocusCountValue"].label, "Completed Increments, 2")

        app.buttons["ResetButton"].tap()
        XCTAssertEqual(app.textFields["FocusTitleField"].value as? String, "Focus Session")
        XCTAssertEqual(app.staticTexts["FocusCountValue"].label, "Completed Increments, 0")
    }

    private func replaceText(in element: XCUIElement, with text: String) {
        element.tap()
        let currentValue = element.value as? String ?? ""
        element.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count))
        element.typeText(text)
    }
}
