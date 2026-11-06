import Foundation

@MainActor
public protocol ItemStore: Plugin {
    func fetchItems() throws -> [ClothingItem]
    func save(_ item: ClothingItem) throws
    func delete(_ item: ClothingItem) throws
}
