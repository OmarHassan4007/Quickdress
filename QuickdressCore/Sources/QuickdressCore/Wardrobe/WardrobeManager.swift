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

    public func addItem(_ item: ClothingItem, photo: Data) throws {
        try validate(item)
        var stored = item
        stored.photo = try photos.savePhoto(photo)
        do {
            try items.save(stored)
        } catch {
            photos.deletePhoto(stored.photo)
            throw error
        }
        bus.publish(.itemSaved(id: stored.id))
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
