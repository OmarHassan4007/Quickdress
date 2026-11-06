import XCTest
import SwiftData
import QuickdressCore
import StoragePlugins

@MainActor
final class SwiftDataItemStoreTests: XCTestCase {
    private func makeStore() throws -> SwiftDataItemStore {
        try SwiftDataItemStore(container: SwiftDataItemStore.makeContainer(inMemory: true))
    }

    private func makeItem(_ category: Category, _ colour: Palette) -> ClothingItem {
        ClothingItem(category: category, colour: colour, warmth: 3, formality: 2, comfort: 4, seasons: [.autumn])
    }

    func testEmptyStoreHasNoItems() throws {
        XCTAssertEqual(try makeStore().fetchItems(), [])
    }

    func testSavedItemsCanBeFetched() throws {
        let store = try makeStore()
        let top = makeItem(.top, .white)
        let shoes = makeItem(.shoes, .black)

        try store.save(top)
        try store.save(shoes)

        XCTAssertEqual(Set(try store.fetchItems()), [top, shoes])
    }

    func testSavingAnExistingItemUpdatesIt() throws {
        let store = try makeStore()
        var item = makeItem(.top, .white)
        try store.save(item)

        item.colour = .green
        item.comfort = 5
        try store.save(item)

        XCTAssertEqual(try store.fetchItems(), [item])
    }

    func testDeleteRemovesTheItem() throws {
        let store = try makeStore()
        let top = makeItem(.top, .white)
        let shoes = makeItem(.shoes, .black)
        try store.save(top)
        try store.save(shoes)

        try store.delete(top)

        XCTAssertEqual(try store.fetchItems(), [shoes])
    }

    func testDeletingAnUnknownItemDoesNothing() throws {
        let store = try makeStore()
        let top = makeItem(.top, .white)
        try store.save(top)

        try store.delete(makeItem(.shoes, .black))

        XCTAssertEqual(try store.fetchItems(), [top])
    }
}
