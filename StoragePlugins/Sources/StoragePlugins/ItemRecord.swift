import Foundation
import SwiftData
import QuickdressCore

@Model
final class ItemRecord {
    @Attribute(.unique) var id: UUID
    var categoryRaw: String
    var colourRaw: String
    var warmth: Int
    var formality: Int
    var comfort: Int
    var seasonsRaw: [String]
    var photo: String
    var createdAt: Date

    init(_ item: ClothingItem, createdAt: Date = .now) {
        self.id = item.id
        self.categoryRaw = item.category.rawValue
        self.colourRaw = item.colour.rawValue
        self.warmth = item.warmth
        self.formality = item.formality
        self.comfort = item.comfort
        self.seasonsRaw = item.seasons.map(\.rawValue).sorted()
        self.photo = item.photo
        self.createdAt = createdAt
    }

    func update(from item: ClothingItem) {
        precondition(item.id == id, "update(from:) called with a different item")
        categoryRaw = item.category.rawValue
        colourRaw = item.colour.rawValue
        warmth = item.warmth
        formality = item.formality
        comfort = item.comfort
        seasonsRaw = item.seasons.map(\.rawValue).sorted()
        photo = item.photo
    }

    func toDomain() throws -> ClothingItem {
        guard let category = Category(rawValue: categoryRaw) else {
            throw ItemRecordError.unknownValue(field: "category", value: categoryRaw, itemID: id)
        }
        guard let colour = Palette(rawValue: colourRaw) else {
            throw ItemRecordError.unknownValue(field: "colour", value: colourRaw, itemID: id)
        }
        var seasons = Set<Season>()
        for raw in seasonsRaw {
            guard let season = Season(rawValue: raw) else {
                throw ItemRecordError.unknownValue(field: "seasons", value: raw, itemID: id)
            }
            seasons.insert(season)
        }
        return ClothingItem(
            id: id,
            category: category,
            colour: colour,
            warmth: warmth,
            formality: formality,
            comfort: comfort,
            seasons: seasons,
            photo: photo
        )
    }
}

enum ItemRecordError: Error, Equatable {
    case unknownValue(field: String, value: String, itemID: UUID)
}
