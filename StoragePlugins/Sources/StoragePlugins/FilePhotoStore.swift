import Foundation
import QuickdressCore

@MainActor
public final class FilePhotoStore: PhotoStore {
    public let id = "storage.files"
    private let directory: URL

    public init(directory: URL? = nil) throws {
        let base: URL
        if let directory {
            base = directory
        } else {
            base = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("Photos", isDirectory: true)
        }
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        self.directory = base
    }

    public func savePhoto(_ data: Data) throws -> PhotoRef {
        let ref = UUID().uuidString + ".jpg"
        try data.write(to: url(for: ref), options: .atomic)
        return ref
    }

    public func loadPhoto(_ ref: PhotoRef) -> Data? {
        try? Data(contentsOf: url(for: ref))
    }

    public func deletePhoto(_ ref: PhotoRef) {
        try? FileManager.default.removeItem(at: url(for: ref))
    }

    private func url(for ref: PhotoRef) -> URL {
        directory.appendingPathComponent(ref, isDirectory: false)
    }
}
