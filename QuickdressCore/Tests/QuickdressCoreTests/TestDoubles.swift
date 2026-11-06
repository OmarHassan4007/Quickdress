import Foundation
import QuickdressCore

enum TestError: Error {
    case saveFailed
}

extension ClothingItem {
    static func sample(_ category: Category = .top, _ colour: Palette = .navy) -> ClothingItem {
        ClothingItem(
            category: category,
            colour: colour,
            warmth: 3,
            formality: 2,
            comfort: 4,
            seasons: [.autumn]
        )
    }
}

@MainActor
final class InMemoryItemStore: ItemStore {
    let id = "test.items"
    var stored: [ClothingItem] = []
    var failNextSave = false

    func fetchItems() throws -> [ClothingItem] {
        stored
    }

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

    func loadPhoto(_ ref: PhotoRef) -> Data? {
        photos[ref]
    }

    func deletePhoto(_ ref: PhotoRef) {
        photos[ref] = nil
    }
}

@MainActor
final class EventLog {
    private(set) var events: [AppEvent] = []

    init(bus: EventBus) {
        bus.subscribe { [weak self] event in
            self?.events.append(event)
        }
    }
}
