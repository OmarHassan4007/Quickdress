import Foundation

@MainActor
public final class WardrobeManager {
    private let items: any ItemStore
    private let photos: any PhotoStore
    private let bus: EventBus

    public init(items: any ItemStore, photos: any PhotoStore, bus: EventBus) {
        self.items = items
        self.photos = photos
        self.bus = bus
    }

    public func allItems() throws -> [ClothingItem] {
        try items.fetchItems()
    }

    public func photo(for item: ClothingItem) -> Data? {
        guard !item.photo.isEmpty else { return nil }
        return photos.loadPhoto(item.photo)
    }

    /// The number the next new item will get: one more than the highest number in the wardrobe.
    public func nextNumber() throws -> Int {
        (try items.fetchItems().map(\.number).max() ?? 0) + 1
    }

    /// Saves a new item and its photo. Returns the item as stored, with its photo
    /// reference and tag number filled in.
    @discardableResult
    public func addItem(_ item: ClothingItem, photo: Data) throws -> ClothingItem {
        try validate(item)
        var stored = item
        if stored.number <= 0 {
            stored.number = try nextNumber()
        }
        stored.photo = try photos.savePhoto(photo)
        do {
            try items.save(stored)
        } catch {
            photos.deletePhoto(stored.photo)
            throw error
        }
        bus.publish(.itemSaved(id: stored.id))
        return stored
    }

    /// Gives a tag number to items saved before numbers existed, oldest first.
    public func numberUnnumberedItems() throws {
        var all = try items.fetchItems()
        var next = (all.map(\.number).max() ?? 0) + 1
        for index in all.indices where all[index].number <= 0 {
            all[index].number = next
            next += 1
            try items.save(all[index])
        }
    }

    public func update(_ item: ClothingItem) throws {
        try validate(item)
        try items.save(item)
        bus.publish(.itemSaved(id: item.id))
    }

    public func delete(_ item: ClothingItem) throws {
        try items.delete(item)
        if !item.photo.isEmpty {
            photos.deletePhoto(item.photo)
        }
        bus.publish(.itemDeleted(id: item.id))
    }

    public func validate(_ item: ClothingItem) throws {
        try item.validate()
    }
}
