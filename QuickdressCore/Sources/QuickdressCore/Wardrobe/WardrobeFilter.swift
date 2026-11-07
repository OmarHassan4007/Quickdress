import Foundation

/// Which items the wardrobe grid shows (FR-04). Every part that is set must match;
/// a part that is not set lets every item through.
public struct WardrobeFilter: Equatable, Sendable {
    public var category: Category?
    public var colour: Palette?
    /// Items worn in any of these seasons. Empty means any season.
    public var seasons: Set<Season>
    /// A band for warmth, formality or comfort. A level with no band is not filtered.
    public var levels: [ClothingItem.Level: LevelBand]

    public init(
        category: Category? = nil,
        colour: Palette? = nil,
        seasons: Set<Season> = [],
        levels: [ClothingItem.Level: LevelBand] = [:]
    ) {
        self.category = category
        self.colour = colour
        self.seasons = seasons
        self.levels = levels
    }

    public var isActive: Bool {
        category != nil || colour != nil || hasAttributeFilters
    }

    /// True when a season or a warmth, formality or comfort band is set.
    public var hasAttributeFilters: Bool {
        !seasons.isEmpty || !levels.isEmpty
    }

    /// How many season and level filters are set, for the filter button's label.
    public var attributeFilterCount: Int {
        seasons.count + levels.count
    }

    public mutating func clearAttributes() {
        seasons = []
        levels = [:]
    }

    public func matches(_ item: ClothingItem) -> Bool {
        if let category, item.category != category {
            return false
        }
        if let colour, item.colour != colour {
            return false
        }
        if !seasons.isEmpty, item.seasons.isDisjoint(with: seasons) {
            return false
        }
        for (level, band) in levels where !band.contains(item[level]) {
            return false
        }
        return true
    }

    public func apply(to items: [ClothingItem]) -> [ClothingItem] {
        items.filter { matches($0) }
    }
}

/// A range of the 1 to 5 scale used to filter warmth, formality and comfort.
public enum LevelBand: String, CaseIterable, Sendable {
    case low
    case medium
    case high

    public var range: ClosedRange<Int> {
        switch self {
        case .low: return 1...2
        case .medium: return 3...3
        case .high: return 4...5
        }
    }

    public func contains(_ level: Int) -> Bool {
        range.contains(level)
    }
}
