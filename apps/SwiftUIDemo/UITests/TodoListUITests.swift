import XCTest

// MARK: - Todo List UI Tests

/// XCUITest flows exercising the SwiftData todo list screen.
internal final class TodoListUITests: SwiftUIDemoUITestCase {

    // MARK: Tests

    /// Navigates to the SwiftData tab, adds a todo item, and asserts it appears in the list.
    internal func testAddTodoItem() throws {
        // Navigate to the SwiftData tab.
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["SwiftData"].tap()

        // Enter a title.
        let field = app.textFields["NewItemField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "New item text field should appear")
        field.tap()
        field.typeText("Buy groceries")

        // Tap Add.
        let addButton = app.buttons["AddItemButton"]
        XCTAssertTrue(addButton.isEnabled, "Add button should be enabled after typing a title")
        addButton.tap()

        // Assert the item appears.
        let itemTitle = app.staticTexts["Buy groceries"]
        XCTAssertTrue(
            itemTitle.waitForExistence(timeout: 5),
            "Newly added todo item should appear in the list"
        )

        // Assert the field cleared after add.
        XCTAssertEqual(field.value as? String, "New item title", "Field should return to its placeholder")

        let completionToggle = app.images["TodoCompletionToggle"]
        XCTAssertTrue(completionToggle.waitForExistence(timeout: 5))
        completionToggle.tap()
        XCTAssertEqual(completionToggle.label, "Mark incomplete")

        app.buttons["DeleteAllButton"].tap()
        XCTAssertFalse(app.staticTexts["Buy groceries"].exists)
    }

    /// Adds two items, deletes one via swipe, and asserts only one remains.
    internal func testDeleteTodoItem() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["SwiftData"].tap()

        // Add first item.
        let field = app.textFields["NewItemField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("First item")
        app.buttons["AddItemButton"].tap()

        // Add second item.
        field.tap()
        field.typeText("Second item")
        app.buttons["AddItemButton"].tap()

        // Wait for both items to appear.
        XCTAssertTrue(
            app.staticTexts["First item"].waitForExistence(timeout: 5),
            "First item should appear"
        )
        XCTAssertTrue(
            app.staticTexts["Second item"].waitForExistence(timeout: 5),
            "Second item should appear"
        )

        // Swipe-delete the first item.
        let firstItemCell = app.staticTexts["First item"].firstMatch
        firstItemCell.swipeLeft()
        app.buttons["Delete"].tap()

        // Assert first item is gone.
        let deletedItem = app.staticTexts["First item"]
        let deletion = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: deletedItem
        )
        wait(for: [deletion], timeout: 5)

        // Assert second item is still there.
        XCTAssertTrue(
            app.staticTexts["Second item"].exists,
            "Remaining item should still appear after deletion of sibling"
        )
    }

    /// Taps the strict insert button and asserts the item appears in the list.
    internal func testStrictInsert() throws {
        let tabBar = app.tabBars.firstMatch
        tabBar.buttons["SwiftData"].tap()

        let strictButton = app.buttons["StrictInsertButton"]
        XCTAssertTrue(strictButton.waitForExistence(timeout: 5), "Strict insert button should appear")
        strictButton.tap()

        // The strict insert adds an item with a time-stamped title starting with "Strict item".
        let strictItem = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Strict item'")).firstMatch
        XCTAssertTrue(
            strictItem.waitForExistence(timeout: 5),
            "Strict-inserted item should appear in the list"
        )
    }
}
