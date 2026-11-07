import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Scales photos down before they are stored or analysed (Design Specification, section 2.3).
public enum ImageScaler {
    /// Longest side of a stored photo, in pixels.
    public static let maxPixelSize = 1600

    /// Decodes any image data, applies its orientation, and returns a CGImage whose
    /// longest side is at most `maxPixelSize`. Returns nil if the data is not an image.
    public static func downscaledImage(from data: Data, maxPixelSize: Int = maxPixelSize) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    /// The same image as JPEG data, scaled so its longest side is at most `maxPixelSize`.
    public static func jpegData(from data: Data, quality: Double = 0.85) -> Data? {
        guard let image = downscaledImage(from: data) else { return nil }
        return encode(image, as: .jpeg, quality: quality)
    }

    static func encode(_ image: CGImage, as type: UTType, quality: Double = 0.85) -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, type.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
