import Foundation

public struct WardrobeFilter: Equatable, Sendable {
    public var category: Category?
    public var colour: Palette?

    public init(category: Category? = nil, colour: Palette? = nil) {
        self.category = category
        self.colour = colour
    }

    public var isActive: Bool {
        category != nil || colour != nil
    }

    public func matches(_ item: ClothingItem) -> Bool {
        if let category, item.category != category {
            return false
        }
        if let colour, item.colour != colour {
            return false
        }
        return true
    }

    public func apply(to items: [ClothingItem]) -> [ClothingItem] {
        items.filter { matches($0) }
    }
}
