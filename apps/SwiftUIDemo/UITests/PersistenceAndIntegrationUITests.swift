import XCTest

// MARK: - Persistence and Integration UI Tests

/// End-to-end journeys for every state wrapper and observable dependency screen.
internal final class PersistenceAndIntegrationUITests: SwiftUIDemoUITestCase {
    internal func testStoredStateCanEditAndClearUsername() {
        app.buttons["UsernameNavLink"].tap()

        let currentValue = app.staticTexts["UsernameCurrentValue"]
        XCTAssertTrue(currentValue.waitForExistence(timeout: 5))
        XCTAssertTrue(currentValue.label.contains("Taylor"))

        app.buttons["ClearUsernameButton"].tap()
        XCTAssertTrue(currentValue.label.contains("empty"))

        let field = app.textFields["UsernameField"]
        field.tap()
        field.typeText("Casey")
        XCTAssertTrue(currentValue.label.contains("Casey"))
    }

    internal func testFileStateCanSaveAndDeleteProfile() {
        app.buttons["ProfileEditorNavLink"].tap()

        let nameField = app.textFields["ProfileDisplayNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Morgan")

        let bioField = app.textFields["ProfileBioField"]
        bioField.tap()
        bioField.typeText("Ships reliable Swift apps")
        app.buttons["SaveProfileButton"].tap()

        XCTAssertTrue(app.staticTexts["SavedProfileName"].label.contains("Morgan"))
        XCTAssertTrue(app.staticTexts["SavedProfileBio"].label.contains("Ships reliable Swift apps"))

        app.buttons["DeleteProfileButton"].tap()
        XCTAssertFalse(app.buttons["DeleteProfileButton"].exists)
    }

    internal func testSlicesMutateIndependentCompositeFields() {
        app.buttons["SlicesNavLink"].tap()

        let fontValue = app.staticTexts["SliceFontSizeValue"]
        XCTAssertTrue(fontValue.waitForExistence(timeout: 5))
        XCTAssertTrue(fontValue.label.contains("14 pt"))

        app.buttons["FontSizeStepper-Increment"].tap()
        XCTAssertTrue(fontValue.label.contains("15 pt"))

        let notifications = app.switches["NotificationsToggle"]
        XCTAssertEqual(notifications.value as? String, "1")
        tapSwitch(notifications)
        waitForValue(of: notifications, equalTo: "0")

        let motto = app.textFields["MottoField"]
        motto.tap()
        motto.typeText("State with confidence")
        XCTAssertTrue(app.staticTexts["SliceMottoValue"].label.contains("State with confidence"))
    }

    internal func testObservedDependencyTicksAndResets() {
        app.tabBars.buttons["Dependencies"].tap()
        app.buttons["ObservedCounterNavLink"].tap()

        let ticks = app.staticTexts["ServiceTicksValue"]
        XCTAssertTrue(ticks.waitForExistence(timeout: 5))
        XCTAssertEqual(ticks.label, "0")

        app.buttons["TickButton"].tap()
        app.buttons["TickButton"].tap()
        XCTAssertEqual(ticks.label, "2")

        app.buttons["ResetServiceButton"].tap()
        XCTAssertEqual(ticks.label, "0")
    }

    internal func testSecureStateCanSaveRevealAndDeleteToken() {
        app.tabBars.buttons["Dependencies"].tap()
        app.buttons["SecureTokenNavLink"].tap()

        let secureField = app.secureTextFields["TokenSecureField"]
        XCTAssertTrue(secureField.waitForExistence(timeout: 5))
        secureField.tap()
        secureField.typeText("demo-secret")
        app.buttons["SaveTokenButton"].tap()

        let currentValue = app.staticTexts["TokenCurrentValue"]
        XCTAssertTrue(currentValue.label.contains("•"))
        tapSwitch(app.switches["RevealTokenToggle"])
        waitForLabel(of: currentValue, containing: "demo-secret")

        app.buttons["DeleteTokenButton"].tap()
        XCTAssertTrue(currentValue.label.contains("no token stored"))
    }

    internal func testSyncStateTogglesAndReturnsToInitialValue() {
        app.tabBars.buttons["Dependencies"].tap()
        app.buttons["ThemeNavLink"].tap()

        let currentValue = app.staticTexts["ThemeCurrentValue"]
        XCTAssertTrue(currentValue.waitForExistence(timeout: 5))
        XCTAssertTrue(currentValue.label.contains("light"))

        let toggle = app.switches["ThemeToggle"]
        tapSwitch(toggle)
        waitForLabel(of: currentValue, containing: "dark")
        tapSwitch(toggle)
        waitForLabel(of: currentValue, containing: "light")
    }
}
