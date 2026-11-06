import Foundation
import SQLite

// Import the enums from their respective files
// Assuming they are part of the same module or accessible via imports
// If they are in the same module, no additional import is needed

public class Database {
    private let db: Connection
    private let clothingItems = Table("clothing_items")

    // Singleton instance
    public static let shared = try! Database()
    
    // Columns
    private let id = Expression<String>("id")
    private let category = Expression<String>("category")
    private let colour = Expression<String>("colour")
    private let warmth = Expression<Int>("warmth")
    private let formality = Expression<Int>("formality")
    private let comfort = Expression<Int>("comfort")
    private let seasons = Expression<String>("seasons")
    private let photo = Expression<String>("photo")

    public init(databasePath: String = "clothing_items.sqlite3") throws {
        // Initialize the database connection
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(databasePath).path
        db = try Connection(path)

        // Create the table if it doesn't exist
        try createTable()
    }

    private func createTable() throws {
        try db.run(clothingItems.create(ifNotExists: true) { table in
            table.column(id, primaryKey: true)
            table.column(category)
            table.column(colour)
            table.column(warmth)
            table.column(formality)
            table.column(comfort)
            table.column(seasons)
            table.column(photo)
        })
    }

    // Insert a new ClothingItem
    public func insert(item: ClothingItem) throws {
        let seasonsString = item.seasons.map { $0.rawValue }.joined(separator: ",")
        try db.run(clothingItems.insert(
            id <- item.id.uuidString,
            category <- item.category.rawValue,
            colour <- item.colour.rawValue,
            warmth <- item.warmth,
            formality <- item.formality,
            comfort <- item.comfort,
            seasons <- seasonsString,
            photo <- item.photo
        ))
    }

    // Fetch all ClothingItems
    public func fetchAll() throws -> [ClothingItem] {
        var items: [ClothingItem] = []
        for row in try db.prepare(clothingItems) {
            let item = ClothingItem(
                id: UUID(uuidString: row[id])!,
                category: Category(rawValue: row[category])!,
                colour: Palette(rawValue: row[colour])!,
                warmth: row[warmth],
                formality: row[formality],
                comfort: row[comfort],
                seasons: Set(row[seasons].split(separator: ",").map { Season(rawValue: String($0))! }),
                photo: row[photo]
            )
            items.append(item)
        }
        return items
    }

    // Update an existing ClothingItem
    public func update(item: ClothingItem) throws {
        let seasonsString = item.seasons.map { $0.rawValue }.joined(separator: ",")
        let query = clothingItems.filter(id == item.id.uuidString)
        try db.run(query.update(
            category <- item.category.rawValue,
            colour <- item.colour.rawValue,
            warmth <- item.warmth,
            formality <- item.formality,
            comfort <- item.comfort,
            seasons <- seasonsString,
            photo <- item.photo
        ))
    }

    // Delete a ClothingItem
    public func delete(itemID: UUID) throws {
        let query = clothingItems.filter(id == itemID.uuidString)
        try db.run(query.delete())
    }
}