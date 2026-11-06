import Foundation

@MainActor
public protocol PhotoStore: Plugin {
    func savePhoto(_ data: Data) throws -> PhotoRef
    func loadPhoto(_ ref: PhotoRef) -> Data?
    func deletePhoto(_ ref: PhotoRef)
}
