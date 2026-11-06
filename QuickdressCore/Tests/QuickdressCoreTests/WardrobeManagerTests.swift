import XCTest
import QuickdressCore

@MainActor
final class WardrobeManagerTests: XCTestCase {
    private struct Subject {
        let manager: WardrobeManager
        let items: InMemoryItemStore
        let photos: InMemoryPhotoStore
        let log: EventLog
    }

    private func makeSubject() -> Subject {
        let items = InMemoryItemStore()
        let photos = InMemoryPhotoStore()
        let bus = EventBus()
        let log = EventLog(bus: bus)
        let manager = WardrobeManager(items: items, photos: photos, bus: bus)
        return Subject(manager: manager, items: items, photos: photos, log: log)
    }

    private let photoData = Data([0xFF, 0xD8, 0xFF])

    func testAddItemSavesThePhotoAndTheItemAndPublishes() throws {
        let subject = makeSubject()
        let item = ClothingItem.sample()

        try subject.manager.addItem(item, photo: photoData)

        XCTAssertEqual(subject.items.stored.count, 1)
        let saved = try XCTUnwrap(subject.items.stored.first)
        XCTAssertEqual(saved.id, item.id)
        XCTAssertFalse(saved.photo.isEmpty)
        XCTAssertEqual(subject.photos.photos[saved.photo], photoData)
        XCTAssertEqual(subject.log.events, [.itemSaved(id: item.id)])
    }

    func testAllItemsReturnsWhatTheStoreHolds() throws {
        let subject = makeSubject()
        let top = ClothingItem.sample(.top)
        let shoes = ClothingItem.sample(.shoes)
        subject.items.stored = [top, shoes]

        XCTAssertEqual(try subject.manager.allItems(), [top, shoes])
    }

    func testPhotoForItemReturnsTheSavedData() throws {
        let subject = makeSubject()
        try subject.manager.addItem(.sample(), photo: photoData)
        let saved = try XCTUnwrap(subject.items.stored.first)

        XCTAssertEqual(subject.manager.photo(for: saved), photoData)
    }

    func testPhotoForItemWithoutPhotoIsNil() {
        let subject = makeSubject()
        XCTAssertNil(subject.manager.photo(for: .sample()))
    }

    func testInvalidItemIsNotSaved() {
        let subject = makeSubject()
        var item = ClothingItem.sample()
        item.warmth = 0

        XCTAssertThrowsError(try subject.manager.addItem(item, photo: photoData))
        XCTAssertTrue(subject.items.stored.isEmpty)
        XCTAssertTrue(subject.photos.photos.isEmpty)
        XCTAssertTrue(subject.log.events.isEmpty)
    }

    func testFailedItemSaveDeletesThePhotoAgain() {
        let subject = makeSubject()
        subject.items.failNextSave = true

        XCTAssertThrowsError(try subject.manager.addItem(.sample(), photo: photoData))
        XCTAssertTrue(subject.items.stored.isEmpty)
        XCTAssertTrue(subject.photos.photos.isEmpty)
        XCTAssertTrue(subject.log.events.isEmpty)
    }

    func testUpdateSavesChangesAndPublishes() throws {
        let subject = makeSubject()
        try subject.manager.addItem(.sample(), photo: photoData)
        var edited = try XCTUnwrap(subject.items.stored.first)
        edited.colour = .red

        try subject.manager.update(edited)

        XCTAssertEqual(subject.items.stored, [edited])
        XCTAssertEqual(subject.log.events.last, .itemSaved(id: edited.id))
    }

    func testDeleteRemovesTheItemAndItsPhotoAndPublishes() throws {
        let subject = makeSubject()
        try subject.manager.addItem(.sample(), photo: photoData)
        let saved = try XCTUnwrap(subject.items.stored.first)

        try subject.manager.delete(saved)

        XCTAssertTrue(subject.items.stored.isEmpty)
        XCTAssertTrue(subject.photos.photos.isEmpty)
        XCTAssertEqual(subject.log.events.last, .itemDeleted(id: saved.id))
    }
}
