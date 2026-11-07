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
        let ref = UUID().uuidString + "." + Self.fileExtension(for: data)
        try data.write(to: url(for: ref), options: .atomic)
        return ref
    }

    public func loadPhoto(_ ref: PhotoRef) -> Data? {
        try? Data(contentsOf: url(for: ref))
    }

    public func deletePhoto(_ ref: PhotoRef) {
        try? FileManager.default.removeItem(at: url(for: ref))
    }

    /// Cut-out photos are PNG (they keep transparency); everything else is stored as JPEG.
    static func fileExtension(for data: Data) -> String {
        data.starts(with: [0x89, 0x50, 0x4E, 0x47]) ? "png" : "jpg"
    }

    private func url(for ref: PhotoRef) -> URL {
        directory.appendingPathComponent(ref, isDirectory: false)
    }
}
