import Foundation
import SwiftData
import QuickdressCore

@MainActor
public final class SwiftDataItemStore: ItemStore {
    public let id = "storage.swiftdata"
    private let container: ModelContainer
    private let context: ModelContext

    public init(container: ModelContainer) {
        self.container = container
        self.context = container.mainContext
    }

    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: ItemRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory)
        )
    }

    public func fetchItems() throws -> [ClothingItem] {
        let descriptor = FetchDescriptor<ItemRecord>(sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    public func save(_ item: ClothingItem) throws {
        if let record = try record(for: item.id) {
            record.update(from: item)
        } else {
            context.insert(ItemRecord(item))
        }
        try context.save()
    }

    public func delete(_ item: ClothingItem) throws {
        guard let record = try record(for: item.id) else { return }
        context.delete(record)
        try context.save()
    }

    private func record(for itemID: UUID) throws -> ItemRecord? {
        var descriptor = FetchDescriptor<ItemRecord>(predicate: #Predicate { $0.id == itemID })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
