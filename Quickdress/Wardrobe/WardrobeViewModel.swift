import Foundation
import Observation
import QuickdressCore

@MainActor
@Observable
final class WardrobeViewModel {
    var filter = WardrobeFilter()
    private(set) var items: [ClothingItem] = []
    private(set) var loadFailed = false

    private let manager: WardrobeManager
    @ObservationIgnored private var photoCache: [UUID: Data] = [:]

    init(manager: WardrobeManager, bus: EventBus) {
        self.manager = manager
        bus.subscribe { [weak self] event in
            self?.handle(event)
        }
    }

    var visibleItems: [ClothingItem] {
        filter.apply(to: items)
    }

    var coloursInWardrobe: [Palette] {
        var present = Set(items.map(\.colour))
        if let selected = filter.colour {
            present.insert(selected)
        }
        return Palette.allCases.filter { present.contains($0) }
    }

    func load() {
        do {
            items = try manager.allItems()
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    func photo(for item: ClothingItem) -> Data? {
        if let cached = photoCache[item.id] {
            return cached
        }
        guard let data = manager.photo(for: item) else { return nil }
        photoCache[item.id] = data
        return data
    }

    func clearFilters() {
        filter = WardrobeFilter()
    }

    private func handle(_ event: AppEvent) {
        switch event {
        case .itemSaved(let id), .itemDeleted(let id):
            photoCache[id] = nil
            load()
        }
    }
}
