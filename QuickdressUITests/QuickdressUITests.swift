import XCTest

/// End-to-end tests of the Sprint 1 user stories, driven through the real screens.
/// The app runs with `-uiTesting`: an empty wardrobe in memory, and a test photo source
/// instead of Apple's camera and photo picker, which run outside the app.
final class QuickdressUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
    }

    // MARK: Helpers

    private func checkInNavyCoat() {
        if app.buttons["Check in your first piece"].exists {
            app.buttons["Check in your first piece"].tap()
        } else {
            app.buttons["Check in a piece"].tap()
        }
        app.buttons["capture.uitest"].tap()
        let save = app.navigationBars.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 10), "The New item screen opens with the photo")
        XCTAssertFalse(save.isEnabled, "Save is off until every answer is set")
        app.buttons["Outerwear"].tap()
        app.buttons["Navy"].tap()
        app.swipeUp()
        app.buttons["Winter"].tap()
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(app.buttons["item.1"].waitForExistence(timeout: 5), "The item is in the wardrobe as No. 001")
    }

    // MARK: Tests

    /// TC-01 (FR-01, FR-02): add an item from a photo and save its details.
    func testAddAnItemFromAPhoto() {
        app.launch()
        XCTAssertTrue(app.staticTexts["Nothing checked in yet"].waitForExistence(timeout: 5))
        checkInNavyCoat()
        app.buttons["item.1"].tap()
        XCTAssertTrue(app.staticTexts["Outerwear"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Navy"].exists)
        XCTAssertTrue(app.staticTexts["Winter"].exists)
    }

    /// TC-02 (FR-01): cancelling a new item keeps nothing.
    func testCancellingANewItemKeepsNothing() {
        app.launch()
        app.buttons["Check in your first piece"].tap()
        app.buttons["capture.uitest"].tap()
        let cancel = app.navigationBars.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 10))
        cancel.tap()
        app.buttons["Discard"].tap()
        XCTAssertTrue(app.staticTexts["Nothing checked in yet"].waitForExistence(timeout: 5))
    }

    /// TC-03 (FR-03): edit an item, then delete it.
    func testEditThenDeleteAnItem() {
        app.launch()
        checkInNavyCoat()
        app.buttons["item.1"].tap()

        app.buttons["Edit or delete"].tap()
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.staticTexts["Edit item"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Retake"].exists, "Editing keeps the saved photo")
        app.buttons["Top"].tap()
        app.navigationBars.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Top"].waitForExistence(timeout: 3), "The detail page shows the edit at once")

        app.buttons["Edit or delete"].tap()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Delete this piece?"].waitForExistence(timeout: 3))
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Nothing checked in yet"].waitForExistence(timeout: 5))
    }

    /// TC-04 (FR-04): filter the grid by category, then by season and warmth.
    func testFilterByCategorySeasonAndWarmth() {
        app.launchArguments.append("-sampleWardrobe")
        app.launch()
        XCTAssertTrue(app.buttons["item.9"].waitForExistence(timeout: 5), "Nine sample pieces")

        app.buttons["Shoes"].tap()
        XCTAssertTrue(app.buttons["item.7"].exists)
        XCTAssertFalse(app.buttons["item.1"].exists)
        app.buttons["All"].tap()

        app.buttons["Filter by season, warmth, formality and comfort"].tap()
        app.buttons["Winter"].tap()
        XCTAssertTrue(app.buttons["Show 4 pieces"].waitForExistence(timeout: 3))
        app.buttons["Warmth: High, 4-5"].tap()
        XCTAssertTrue(app.buttons["Show 1 piece"].exists)
        app.buttons["Show 1 piece"].tap()

        XCTAssertTrue(app.buttons["item.6"].waitForExistence(timeout: 3), "Only the grey winter coat is left")
        XCTAssertFalse(app.buttons["item.2"].exists)

        app.buttons["Remove filter: Warmth High"].tap()
        XCTAssertTrue(app.buttons["item.2"].waitForExistence(timeout: 3), "Removing the warmth filter brings back the other winter pieces")
    }
}
