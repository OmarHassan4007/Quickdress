import Foundation

/// Where a photo of a new item comes from: the camera or the photo library (FR-01).
/// Implemented by the plug-ins in `CapturePlugins`. The core only knows this contract.
@MainActor
public protocol ImageSource: Plugin {
    /// Shown to the user on the add sheet, for example "Take a photo".
    var title: String { get }
    /// False when the source cannot work on this device, such as the camera on the Simulator.
    var isAvailable: Bool { get }
    /// Whether the user has allowed this source. Sources that need no permission report `.granted`.
    var access: ImageSourceAccess { get }
    /// Asks for permission if it has not been asked yet. Returns true if the source may be used.
    func requestAccess() async -> Bool
    /// Lets the user take or pick one photo and returns it as image data (JPEG),
    /// scaled so its longest side is at most 1,600 pixels.
    /// Throws `ImageSourceError.cancelled` if the user backs out.
    func capture() async throws -> Data
}

public enum ImageSourceAccess: Sendable, Equatable {
    case notDetermined
    case granted
    case denied
}

public enum ImageSourceError: Error, Equatable, Sendable {
    case cancelled
    case unavailable
    case accessDenied
    case unreadableImage
}
