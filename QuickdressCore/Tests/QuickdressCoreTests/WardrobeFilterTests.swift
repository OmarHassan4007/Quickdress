import XCTest
import QuickdressCore

final class WardrobeFilterTests: XCTestCase {
    private let navyTop = ClothingItem.sample(.top, .navy)
    private let redTop = ClothingItem.sample(.top, .red)
    private let navyShoes = ClothingItem.sample(.shoes, .navy)

    private var wardrobe: [ClothingItem] {
        [navyTop, redTop, navyShoes]
    }

    func testNoFilterKeepsEveryItemInOrder() {
        let filter = WardrobeFilter()
        XCTAssertFalse(filter.isActive)
        XCTAssertEqual(filter.apply(to: wardrobe), wardrobe)
    }

    func testCategoryFilterKeepsOnlyThatCategory() {
        let filter = WardrobeFilter(category: .top)
        XCTAssertTrue(filter.isActive)
        XCTAssertEqual(filter.apply(to: wardrobe), [navyTop, redTop])
    }

    func testColourFilterKeepsOnlyThatColour() {
        XCTAssertEqual(WardrobeFilter(colour: .navy).apply(to: wardrobe), [navyTop, navyShoes])
    }

    func testCategoryAndColourMustBothMatch() {
        XCTAssertEqual(WardrobeFilter(category: .shoes, colour: .navy).apply(to: wardrobe), [navyShoes])
    }

    func testFilterWithNoMatchesReturnsNothing() {
        XCTAssertEqual(WardrobeFilter(category: .outerwear).apply(to: wardrobe), [])
        XCTAssertEqual(WardrobeFilter(category: .shoes, colour: .red).apply(to: wardrobe), [])
    }

    // MARK: Attribute filters (season, warmth, formality, comfort)

    private func item(
        warmth: Int = 3, formality: Int = 3, comfort: Int = 3, seasons: Set<Season> = [.autumn]
    ) -> ClothingItem {
        ClothingItem(category: .top, colour: .navy, warmth: warmth, formality: formality, comfort: comfort, seasons: seasons)
    }

    func testSeasonFilterKeepsItemsWornInAnySelectedSeason() {
        let coat = item(seasons: [.winter, .autumn])
        let tee = item(seasons: [.summer])
        let jacket = item(seasons: [.spring, .autumn])
        let filter = WardrobeFilter(seasons: [.winter, .spring])
        XCTAssertEqual(filter.apply(to: [coat, tee, jacket]), [coat, jacket])
    }

    func testLevelBandBoundaries() {
        // Boundary values of each band on the 1 to 5 scale.
        XCTAssertTrue(LevelBand.low.contains(1))
        XCTAssertTrue(LevelBand.low.contains(2))
        XCTAssertFalse(LevelBand.low.contains(3))
        XCTAssertFalse(LevelBand.medium.contains(2))
        XCTAssertTrue(LevelBand.medium.contains(3))
        XCTAssertFalse(LevelBand.medium.contains(4))
        XCTAssertFalse(LevelBand.high.contains(3))
        XCTAssertTrue(LevelBand.high.contains(4))
        XCTAssertTrue(LevelBand.high.contains(5))
    }

    func testWarmthBandKeepsOnlyItemsInThatBand() {
        let light = item(warmth: 2)
        let mid = item(warmth: 3)
        let warm = item(warmth: 5)
        XCTAssertEqual(WardrobeFilter(levels: [.warmth: .high]).apply(to: [light, mid, warm]), [warm])
        XCTAssertEqual(WardrobeFilter(levels: [.warmth: .low]).apply(to: [light, mid, warm]), [light])
    }

    func testEveryAttributeFilterMustMatch() {
        let formalWinter = item(formality: 5, comfort: 2, seasons: [.winter])
        let formalSummer = item(formality: 4, comfort: 2, seasons: [.summer])
        let casualWinter = item(formality: 1, comfort: 5, seasons: [.winter])
        let filter = WardrobeFilter(seasons: [.winter], levels: [.formality: .high, .comfort: .low])
        XCTAssertEqual(filter.apply(to: [formalWinter, formalSummer, casualWinter]), [formalWinter])
    }

    func testAttributeFiltersCombineWithCategoryAndColour() {
        let navyWinterTop = ClothingItem(category: .top, colour: .navy, warmth: 4, formality: 2, comfort: 4, seasons: [.winter])
        let navyWinterShoes = ClothingItem(category: .shoes, colour: .navy, warmth: 4, formality: 2, comfort: 4, seasons: [.winter])
        let filter = WardrobeFilter(category: .top, colour: .navy, seasons: [.winter], levels: [.warmth: .high])
        XCTAssertEqual(filter.apply(to: [navyWinterTop, navyWinterShoes]), [navyWinterTop])
    }

    func testAttributeFilterCountAndClear() {
        var filter = WardrobeFilter(category: .top, seasons: [.winter, .summer], levels: [.comfort: .high])
        XCTAssertTrue(filter.hasAttributeFilters)
        XCTAssertEqual(filter.attributeFilterCount, 3)
        filter.clearAttributes()
        XCTAssertFalse(filter.hasAttributeFilters)
        XCTAssertEqual(filter.attributeFilterCount, 0)
        XCTAssertEqual(filter.category, .top, "Clearing attributes keeps the category and colour")
        XCTAssertTrue(filter.isActive)
    }
}
