#if DEBUG
import UIKit
import QuickdressCore

/// Launch arguments used by the UI tests (QuickdressUITests). Debug builds only.
enum UITestSupport {
    /// Starts with an empty wardrobe in memory, and replaces the camera and photo picker
    /// (which run outside the app and can't be driven by a test) with `UITestPhotoSource`.
    static var isUITesting: Bool { ProcessInfo.processInfo.arguments.contains("-uiTesting") }
}

/// Returns a generated photo of a navy garment instead of opening Apple's photo picker.
@MainActor
final class UITestPhotoSource: ImageSource {
    let id = "capture.uitest"
    let priority = 10
    let title = String(localized: "Choose from library")
    let isAvailable = true
    let access = ImageSourceAccess.granted

    func requestAccess() async -> Bool { true }

    func capture() async throws -> Data {
        let size = CGSize(width: 900, height: 1200)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.93, green: 0.92, blue: 0.9, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor(red: 0.12, green: 0.15, blue: 0.3, alpha: 1).setFill()
            context.fill(CGRect(x: 180, y: 240, width: 540, height: 720))
        }
        guard let data = image.jpegData(compressionQuality: 0.85) else { throw ImageSourceError.unreadableImage }
        return data
    }
}
#endif
