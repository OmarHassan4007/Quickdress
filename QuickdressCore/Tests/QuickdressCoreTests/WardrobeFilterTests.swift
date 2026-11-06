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
}
