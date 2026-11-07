#if canImport(UIKit)
import PhotosUI
import UIKit
import QuickdressCore

/// Picks one photo with Apple's photo picker. The picker runs outside the app,
/// so it needs no Photos permission and is always available (NFR-07).
@MainActor
public final class PhotoLibrarySource: NSObject, ImageSource {
    public let id = "capture.library"
    public let priority = 10
    public let title = String(localized: "Choose from library")
    public let isAvailable = true
    public let access = ImageSourceAccess.granted

    private var continuation: CheckedContinuation<Data, Error>?

    public override init() {}

    public func requestAccess() async -> Bool { true }

    public func capture() async throws -> Data {
        guard let presenter = UIApplication.shared.topViewController else { throw ImageSourceError.unavailable }
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            presenter.present(picker, animated: true)
        }
    }

    private func finish(_ result: Result<Data, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}

extension PhotoLibrarySource: PHPickerViewControllerDelegate {
    nonisolated public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        MainActor.assumeIsolated {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider else {
                finish(.failure(ImageSourceError.cancelled))
                return
            }
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                let scaled = data.flatMap { ImageScaler.jpegData(from: $0) }
                Task { @MainActor in
                    if let scaled {
                        self.finish(.success(scaled))
                    } else {
                        self.finish(.failure(ImageSourceError.unreadableImage))
                    }
                }
            }
        }
    }
}
#endif
