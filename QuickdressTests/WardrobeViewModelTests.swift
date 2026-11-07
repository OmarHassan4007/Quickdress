import XCTest
import QuickdressCore
@testable import Quickdress

/// FR-03 (delete) and FR-04 (grid filters) through the Wardrobe screen's model.
@MainActor
final class WardrobeViewModelTests: XCTestCase {
    private let coat = ClothingItem(category: .outerwear, colour: .grey, warmth: 5, formality: 3, comfort: 3, seasons: [.winter])
    private let tee = ClothingItem(category: .top, colour: .white, warmth: 1, formality: 1, comfort: 5, seasons: [.summer])
    private let shirt = ClothingItem(category: .top, colour: .navy, warmth: 3, formality: 4, comfort: 3, seasons: [.autumn, .winter])

    private func makeModel() throws -> (WardrobeViewModel, TestWardrobe) {
        let wardrobe = TestWardrobe()
        for item in [coat, tee, shirt] {
            try wardrobe.manager.addItem(item, photo: TestWardrobe.jpeg)
        }
        let model = WardrobeViewModel(manager: wardrobe.manager, bus: wardrobe.bus)
        model.load()
        return (model, wardrobe)
    }

    func testLoadShowsEveryItem() throws {
        let (model, _) = try makeModel()
        XCTAssertEqual(model.visibleItems.map(\.id), [coat.id, tee.id, shirt.id])
        XCTAssertEqual(model.coloursInWardrobe, [.white, .grey, .navy])
    }

    func testCategoryAndSeasonFiltersCombine() throws {
        let (model, _) = try makeModel()
        model.filter.category = .top
        model.filter.seasons = [.winter]
        XCTAssertEqual(model.visibleItems.map(\.id), [shirt.id])
    }

    func testRatingBandFilter() throws {
        let (model, _) = try makeModel()
        model.filter.levels[.formality] = .high
        XCTAssertEqual(model.visibleItems.map(\.id), [shirt.id])
        model.filter.levels[.formality] = .low
        XCTAssertEqual(model.visibleItems.map(\.id), [tee.id])
    }

    func testClearFiltersShowsEverythingAgain() throws {
        let (model, _) = try makeModel()
        model.filter = WardrobeFilter(category: .shoes, seasons: [.spring], levels: [.warmth: .high])
        XCTAssertTrue(model.visibleItems.isEmpty)
        model.clearFilters()
        XCTAssertEqual(model.visibleItems.count, 3)
    }

    func testDeletingAnItemRemovesItAndItsPhotoAndRefreshesTheGrid() throws {
        let (model, wardrobe) = try makeModel()
        let stored = try XCTUnwrap(model.items.first { $0.id == tee.id })
        try wardrobe.manager.delete(stored)
        XCTAssertFalse(model.items.contains { $0.id == tee.id }, "The grid reloads when the item is deleted")
        XCTAssertNil(wardrobe.photos.photos[stored.photo])
        XCTAssertEqual(model.items.count, 2)
    }

    func testAnEditShowsUpInTheGridRightAway() throws {
        let (model, wardrobe) = try makeModel()
        var edited = try XCTUnwrap(model.items.first { $0.id == coat.id })
        edited.colour = .black
        try wardrobe.manager.update(edited)
        XCTAssertEqual(model.items.first { $0.id == coat.id }?.colour, .black)
    }
}
