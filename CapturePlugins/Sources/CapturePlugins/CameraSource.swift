#if canImport(UIKit)
import AVFoundation
import UIKit
import QuickdressCore

/// Takes a photo with Apple's camera screen (`UIImagePickerController`).
/// Reports itself unavailable on the Simulator, which has no camera (risk R10).
@MainActor
public final class CameraSource: NSObject, ImageSource {
    public let id = "capture.camera"
    public let priority = 20
    public let title = String(localized: "Take a photo")

    private var continuation: CheckedContinuation<Data, Error>?

    public override init() {}

    public var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    public var access: ImageSourceAccess {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .granted
        case .notDetermined: return .notDetermined
        default: return .denied
        }
    }

    public func requestAccess() async -> Bool {
        switch access {
        case .granted: return true
        case .denied: return false
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        }
    }

    public func capture() async throws -> Data {
        guard isAvailable else { throw ImageSourceError.unavailable }
        guard await requestAccess() else { throw ImageSourceError.accessDenied }
        guard let presenter = UIApplication.shared.topViewController else { throw ImageSourceError.unavailable }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = self
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            presenter.present(picker, animated: true)
        }
    }

    private func finish(_ result: Result<Data, Error>, picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        continuation?.resume(with: result)
        continuation = nil
    }
}

extension CameraSource: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    nonisolated public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = info[.originalImage] as? UIImage
        MainActor.assumeIsolated {
            guard let data = image?.jpegData(compressionQuality: 0.95).flatMap({ ImageScaler.jpegData(from: $0) }) else {
                finish(.failure(ImageSourceError.unreadableImage), picker: picker)
                return
            }
            finish(.success(data), picker: picker)
        }
    }

    nonisolated public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        MainActor.assumeIsolated {
            finish(.failure(ImageSourceError.cancelled), picker: picker)
        }
    }
}
#endif
