import XCTest
import StoragePlugins

@MainActor
final class FilePhotoStoreTests: XCTestCase {
    private func makeStore() throws -> FilePhotoStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return try FilePhotoStore(directory: directory)
    }

    private let photoData = Data([0xFF, 0xD8, 0xFF, 0xE0])

    func testSavedPhotoLoadsBack() throws {
        let store = try makeStore()
        let ref = try store.savePhoto(photoData)

        XCTAssertEqual(store.loadPhoto(ref), photoData)
    }

    func testEachPhotoGetsItsOwnReference() throws {
        let store = try makeStore()
        let first = try store.savePhoto(photoData)
        let second = try store.savePhoto(photoData)

        XCTAssertNotEqual(first, second)
    }

    func testDeletedPhotoIsGone() throws {
        let store = try makeStore()
        let ref = try store.savePhoto(photoData)

        store.deletePhoto(ref)

        XCTAssertNil(store.loadPhoto(ref))
    }

    func testUnknownReferenceLoadsNothing() throws {
        XCTAssertNil(try makeStore().loadPhoto("missing.jpg"))
    }
}
