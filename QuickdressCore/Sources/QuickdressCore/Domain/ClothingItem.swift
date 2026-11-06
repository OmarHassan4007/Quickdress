import Foundation

public struct ClothingItem: Identifiable, Hashable, Codable, Sendable {
    public static let levelRange: ClosedRange<Int> = 1...5

    public let id: UUID
    public var category: Category
    public var colour: Palette
    public var warmth: Int
    public var formality: Int
    public var comfort: Int
    public var seasons: Set<Season>
    public var photo: PhotoRef

    public init(
        id: UUID = UUID(),
        category: Category,
        colour: Palette,
        warmth: Int,
        formality: Int,
        comfort: Int,
        seasons: Set<Season>,
        photo: PhotoRef = ""
    ) {
        self.id = id
        self.category = category
        self.colour = colour
        self.warmth = warmth
        self.formality = formality
        self.comfort = comfort
        self.seasons = seasons
        self.photo = photo
    }
}

extension ClothingItem {
    public enum Level: String, CaseIterable, Sendable {
        case warmth, formality, comfort
    }

    public enum ValidationError: Error, Equatable, Sendable {
        case levelOutOfRange(Level, value: Int)
        case noSeason
    }

    public subscript(level: Level) -> Int {
        switch level {
        case .warmth: return warmth
        case .formality: return formality
        case .comfort: return comfort
        }
    }

    public var validationErrors: [ValidationError] {
        var errors: [ValidationError] = []
        for level in Level.allCases {
            let value = self[level]
            if !Self.levelRange.contains(value) {
                errors.append(.levelOutOfRange(level, value: value))
            }
        }
        if seasons.isEmpty {
            errors.append(.noSeason)
        }
        return errors
    }

    public var isValid: Bool { validationErrors.isEmpty }

    public func validate() throws {
        if let first = validationErrors.first {
            throw first
        }
    }
}
