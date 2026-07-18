import XCTest

// MARK: - SwiftUI Demo UI Test Case

/// Shared deterministic launch and visual-evidence helpers.
@MainActor
internal class SwiftUIDemoUITestCase: XCTestCase {
    internal lazy var app: XCUIApplication = {
        continueAfterFailure = false
        let application = XCUIApplication()
        application.launchArguments = ["--ui-testing"]
        application.launch()
        return application
    }()

    internal func captureSnapshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    internal func waitForLabel(of element: XCUIElement, containing text: String, timeout: TimeInterval = 5) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let labelExpectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [labelExpectation], timeout: timeout), .completed)
    }

    internal func waitForValue(of element: XCUIElement, equalTo value: String, timeout: TimeInterval = 5) {
        let predicate = NSPredicate(format: "value == %@", value)
        let valueExpectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [valueExpectation], timeout: timeout), .completed)
    }

    internal func tapSwitch(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        XCTAssertTrue(element.isHittable)
        guard let initialValue = element.value as? String else {
            element.tap()
            return
        }

        let expectedValue = initialValue == "1" ? "0" : "1"
        element.tap()
        if !hasValue(element, equalTo: expectedValue, timeout: 1) {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            XCTAssertTrue(hasValue(element, equalTo: expectedValue, timeout: 5))
        }
    }

    private func hasValue(_ element: XCUIElement, equalTo value: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "value == %@", value)
        let valueExpectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [valueExpectation], timeout: timeout) == .completed
    }
}
