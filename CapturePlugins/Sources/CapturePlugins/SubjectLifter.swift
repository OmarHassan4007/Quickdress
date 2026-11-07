import Foundation
import CoreImage
import Vision
import UniformTypeIdentifiers
import os

/// Cuts the garment out of its photo on the device, with Apple's Vision framework.
/// A helper used by the add-item screens, not a plug-in contract.
let logger = Logger(subsystem: "edu.aucegypt.quickdress", category: "capture")

public struct SubjectLifter: Sendable {
    public init() {}

    /// Returns the subject of the photo as PNG data with a transparent background,
    /// cropped to the subject, or nil if Vision finds no subject or the data is not an image.
    public func lift(_ photo: Data) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            Self.liftSync(photo)
        }.value
    }

    static func liftSync(_ photo: Data) -> Data? {
        guard let image = ImageScaler.downscaledImage(from: photo) else { return nil }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: image)
        do {
            try handler.perform([request])
            guard let result = request.results?.first, !result.allInstances.isEmpty else {
                logger.info("Cut-out: no subject found")
                return nil
            }
            let buffer = try result.generateMaskedImage(
                ofInstances: result.allInstances,
                from: handler,
                croppedToInstancesExtent: true
            )
            let ciImage = CIImage(cvPixelBuffer: buffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
            return ImageScaler.encode(cgImage, as: .png)
        } catch {
            logger.error("Cut-out failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
