import Foundation
import QuickdressCore

enum TestError: Error {
    case saveFailed
}

@MainActor
final class InMemoryItemStore: ItemStore {
    let id = "test.items"
    var stored: [ClothingItem] = []
    var failNextSave = false

    func fetchItems() throws -> [ClothingItem] { stored }

    func save(_ item: ClothingItem) throws {
        if failNextSave {
            failNextSave = false
            throw TestError.saveFailed
        }
        if let index = stored.firstIndex(where: { $0.id == item.id }) {
            stored[index] = item
        } else {
            stored.append(item)
        }
    }

    func delete(_ item: ClothingItem) throws {
        stored.removeAll { $0.id == item.id }
    }
}

@MainActor
final class InMemoryPhotoStore: PhotoStore {
    let id = "test.photos"
    var photos: [PhotoRef: Data] = [:]

    func savePhoto(_ data: Data) throws -> PhotoRef {
        let ref = UUID().uuidString
        photos[ref] = data
        return ref
    }

    func loadPhoto(_ ref: PhotoRef) -> Data? { photos[ref] }

    func deletePhoto(_ ref: PhotoRef) { photos[ref] = nil }
}

/// A wardrobe with in-memory storage, for testing the screens' models without the app's real files.
@MainActor
struct TestWardrobe {
    let bus = EventBus()
    let items = InMemoryItemStore()
    let photos = InMemoryPhotoStore()
    let manager: WardrobeManager

    init() {
        manager = WardrobeManager(items: items, photos: photos, bus: bus)
    }

    /// Bytes that start like a JPEG, standing in for a photo.
    static let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02])
    /// Bytes that start like a PNG, standing in for a cut-out.
    static let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A])
}
