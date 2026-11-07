import XCTest
import QuickdressCore
import CapturePlugins
@testable import Quickdress

/// FR-01, FR-02, FR-03 and FR-13 through the New item and Edit item screen's model.
@MainActor
final class CheckInViewModelTests: XCTestCase {
    private func answerEverything(_ model: CheckInViewModel) {
        model.choose(QuickdressCore.Category.outerwear)
        model.choose(Palette.navy)
        model.toggle(.winter)
    }

    // MARK: New item

    func testNewItemCannotBeSavedUntilCategoryColourAndSeasonAreAnswered() {
        let wardrobe = TestWardrobe()
        let model = CheckInViewModel(photo: TestWardrobe.jpeg, manager: wardrobe.manager)
        XCTAssertFalse(model.canSave)
        model.choose(QuickdressCore.Category.outerwear)
        XCTAssertFalse(model.canSave, "Colour and season are still missing")
        model.choose(Palette.navy)
        XCTAssertFalse(model.canSave, "Season is still missing")
        model.toggle(.winter)
        XCTAssertTrue(model.canSave)
        model.toggle(.winter)
        XCTAssertFalse(model.canSave, "Removing the only season makes the item incomplete again")
        XCTAssertFalse(model.save(), "Save does nothing while an answer is missing")
        XCTAssertTrue(wardrobe.items.stored.isEmpty)
    }

    func testSavingANewItemStoresItsAnswersPhotoAndNextNumber() throws {
        let wardrobe = TestWardrobe()
        let first = CheckInViewModel(photo: TestWardrobe.jpeg, manager: wardrobe.manager)
        answerEverything(first)
        first.setLevel(.warmth, to: 5)
        first.setLevel(.formality, to: 2)
        first.setLevel(.comfort, to: 4)
        XCTAssertTrue(first.save())

        let saved = try XCTUnwrap(wardrobe.items.stored.first)
        XCTAssertEqual(saved.category, .outerwear)
        XCTAssertEqual(saved.colour, .navy)
        XCTAssertEqual(saved.seasons, [.winter])
        XCTAssertEqual([saved.warmth, saved.formality, saved.comfort], [5, 2, 4])
        XCTAssertEqual(saved.number, 1)
        XCTAssertEqual(wardrobe.photos.photos[saved.photo], TestWardrobe.jpeg)

        let second = CheckInViewModel(photo: TestWardrobe.jpeg, manager: wardrobe.manager)
        XCTAssertEqual(second.tagText, "No. 002", "The next item gets the next tag number")
    }

    func testAFailedSaveKeepsNothingAndShowsAnError() {
        let wardrobe = TestWardrobe()
        let model = CheckInViewModel(photo: TestWardrobe.jpeg, manager: wardrobe.manager)
        answerEverything(model)
        wardrobe.items.failNextSave = true
        XCTAssertFalse(model.save())
        XCTAssertNotNil(model.saveError)
        XCTAssertTrue(wardrobe.items.stored.isEmpty)
        XCTAssertTrue(wardrobe.photos.photos.isEmpty, "The photo is removed again when the item can't be saved")
    }

    // MARK: Suggestions (FR-13)

    func testSuggestionsFillUnansweredLinesAndAreMarkedForChecking() {
        let wardrobe = TestWardrobe()
        let model = CheckInViewModel(photo: TestWardrobe.jpeg, manager: wardrobe.manager)
        var suggestion = ItemSuggestion()
        suggestion.category = .outerwear
        suggestion.exactColour = RGB(0.14, 0.15, 0.2)
        suggestion.warmth = 4
        suggestion.seasons = [.autumn, .winter]
        model.apply(suggestion)

        XCTAssertEqual(model.category, .outerwear)
        XCTAssertEqual(model.colour, .navy)
        XCTAssertEqual(model.warmth, 4)
        XCTAssertEqual(model.seasons, [.autumn, .winter])
        XCTAssertTrue(model.suggested.isSuperset(of: [.category, .colour, .warmth, .season]))
        XCTAssertTrue(model.canSave, "A complete suggestion can be saved as it is")
    }

    func testSuggestionsNeverOverwriteWhatTheUserChose() {
        let wardrobe = TestWardrobe()
        let model = CheckInViewModel(photo: TestWardrobe.jpeg, manager: wardrobe.manager)
        model.choose(QuickdressCore.Category.shoes)
        var suggestion = ItemSuggestion()
        suggestion.category = .top
        model.apply(suggestion)
        XCTAssertEqual(model.category, .shoes)
        XCTAssertFalse(model.suggested.contains(.category))
    }

    func testChangingASuggestedAnswerRemovesItsMark() {
        let wardrobe = TestWardrobe()
        let model = CheckInViewModel(photo: TestWardrobe.jpeg, manager: wardrobe.manager)
        var suggestion = ItemSuggestion()
        suggestion.category = .top
        suggestion.warmth = 2
        model.apply(suggestion)
        model.choose(QuickdressCore.Category.bottom)
        model.adjust(.warmth, by: 1)
        XCTAssertFalse(model.suggested.contains(.category))
        XCTAssertFalse(model.suggested.contains(.warmth))
        XCTAssertEqual(model.warmth, 3)
    }

    func testRatingsStayBetweenOneAndFive() {
        let wardrobe = TestWardrobe()
        let model = CheckInViewModel(photo: TestWardrobe.jpeg, manager: wardrobe.manager)
        model.setLevel(.comfort, to: 5)
        model.adjust(.comfort, by: 1)
        XCTAssertEqual(model.comfort, 5)
        model.setLevel(.comfort, to: 1)
        model.adjust(.comfort, by: -1)
        XCTAssertEqual(model.comfort, 1)
    }

    func testExactColourIsKeptAndNamedByTheNearestPaletteColour() throws {
        let wardrobe = TestWardrobe()
        let model = CheckInViewModel(photo: TestWardrobe.jpeg, manager: wardrobe.manager)
        model.chooseExact(RGB(0.8, 0.12, 0.14))
        XCTAssertEqual(model.colour, .red)
        model.choose(QuickdressCore.Category.top)
        model.toggle(.summer)
        XCTAssertTrue(model.save())
        XCTAssertEqual(try XCTUnwrap(wardrobe.items.stored.first).exactColour, model.exactColour?.hex)

        model.choose(Palette.blue)
        XCTAssertNil(model.exactColour, "Picking a palette swatch clears the exact colour")
    }

    // MARK: Edit item (FR-03)

    private func savedItem(in wardrobe: TestWardrobe, photo: Data = TestWardrobe.jpeg) throws -> ClothingItem {
        let item = ClothingItem(category: .top, colour: .white, warmth: 2, formality: 3, comfort: 4, seasons: [.summer])
        return try wardrobe.manager.addItem(item, photo: photo)
    }

    func testEditLoadsTheSavedAnswersAndSkipsTheCutOut() throws {
        let wardrobe = TestWardrobe()
        let item = try savedItem(in: wardrobe)
        let model = CheckInViewModel(item: item, manager: wardrobe.manager)
        model.start()
        XCTAssertFalse(model.isNewItem)
        XCTAssertFalse(model.isCuttingOut, "Editing never runs the cut-out again")
        XCTAssertEqual(model.category, .top)
        XCTAssertEqual(model.colour, .white)
        XCTAssertEqual(model.seasons, [.summer])
        XCTAssertEqual([model.warmth, model.formality, model.comfort], [2, 3, 4])
        XCTAssertEqual(model.tagText, item.tagText)
        XCTAssertTrue(model.canSave)
    }

    func testSavingAnEditUpdatesTheSameItemAndKeepsItsPhotoAndNumber() throws {
        let wardrobe = TestWardrobe()
        let item = try savedItem(in: wardrobe)
        let model = CheckInViewModel(item: item, manager: wardrobe.manager)
        model.choose(QuickdressCore.Category.outerwear)
        model.toggle(.winter)
        XCTAssertTrue(model.save())

        XCTAssertEqual(wardrobe.items.stored.count, 1, "Editing doesn't add a second item")
        let updated = try XCTUnwrap(wardrobe.items.stored.first)
        XCTAssertEqual(updated.id, item.id)
        XCTAssertEqual(updated.category, .outerwear)
        XCTAssertEqual(updated.seasons, [.summer, .winter])
        XCTAssertEqual(updated.photo, item.photo)
        XCTAssertEqual(updated.number, item.number)
        XCTAssertEqual(wardrobe.photos.photos.count, 1, "Editing doesn't store the photo again")
    }

    func testEditShowsASavedCutOutAsACutOut() throws {
        let wardrobe = TestWardrobe()
        let cutOut = try savedItem(in: wardrobe, photo: TestWardrobe.png)
        XCTAssertTrue(CheckInViewModel(item: cutOut, manager: wardrobe.manager).showsCutOut)
        let photo = try savedItem(in: wardrobe, photo: TestWardrobe.jpeg)
        XCTAssertFalse(CheckInViewModel(item: photo, manager: wardrobe.manager).showsCutOut)
    }
}
