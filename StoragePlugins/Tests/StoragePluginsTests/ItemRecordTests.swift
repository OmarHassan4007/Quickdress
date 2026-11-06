import XCTest
import SwiftData
import QuickdressCore
@testable import StoragePlugins

final class ItemRecordTests: XCTestCase {
    private var context: ModelContext!

    override func setUpWithError() throws {
        let container = try ModelContainer(
            for: ItemRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
    }

    private let shirt = ClothingItem(
        category: .top, colour: .white, warmth: 2, formality: 4, comfort: 3,
        seasons: [.summer, .spring], photo: "shirt.jpg"
    )

    func testRecordRoundTripsToTheSameItem() throws {
        let record = ItemRecord(shirt)
        context.insert(record)
        try context.save()
        XCTAssertEqual(try record.toDomain(), shirt)
        XCTAssertEqual(record.seasonsRaw, ["spring", "summer"])
    }

    func testUpdateChangesAttributesButNotIdentity() throws {
        let record = ItemRecord(shirt, createdAt: Date(timeIntervalSince1970: 0))
        var edited = shirt
        edited.colour = .blue
        edited.comfort = 5
        record.update(from: edited)
        XCTAssertEqual(try record.toDomain(), edited)
        XCTAssertEqual(record.createdAt, Date(timeIntervalSince1970: 0))
    }

    func testUnknownStoredValueThrows() {
        let record = ItemRecord(shirt)
        record.colourRaw = "teal"
        XCTAssertThrowsError(try record.toDomain()) { error in
            XCTAssertEqual(
                error as? ItemRecordError,
                .unknownValue(field: "colour", value: "teal", itemID: self.shirt.id)
            )
        }
    }

    func testWardrobeCanBeFilteredByCategory() throws {
        let shoes = ClothingItem(category: .shoes, colour: .black, warmth: 3, formality: 3, comfort: 4, seasons: [.winter])
        context.insert(ItemRecord(shirt))
        context.insert(ItemRecord(shoes))
        try context.save()

        let raw = Category.shoes.rawValue
        let descriptor = FetchDescriptor<ItemRecord>(predicate: #Predicate { $0.categoryRaw == raw })
        let found = try context.fetch(descriptor).map { try $0.toDomain() }
        XCTAssertEqual(found, [shoes])
    }
}
