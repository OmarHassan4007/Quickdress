import Foundation
import CoreGraphics
import Vision
import QuickdressCore

/// What the app could tell about a photographed garment. Every field is a suggestion
/// the user confirms or corrects on the receipt (FR-13). Nil means "no suggestion".
public struct ItemSuggestion: Equatable, Sendable {
    public var category: QuickdressCore.Category?
    public var exactColour: RGB?
    public var colour: Palette? { exactColour.map(Palette.nearest(to:)) }
    public var warmth: Int?
    public var formality: Int?
    public var comfort: Int?
    public var seasons: Set<Season> = []
    /// The labels Vision returned, strongest first, for debugging and tests.
    public var labels: [String] = []

    public init() {}
}

/// Fills in a new item's details on the phone, with no network call:
/// Apple's built-in image classifier for the type, and the cut-out's own pixels for the colour.
public struct ItemAnalyzer: Sendable {
    public init() {}

    public func suggest(for photo: Data) async -> ItemSuggestion {
        await Task.detached(priority: .userInitiated) { Self.suggestSync(photo) }.value
    }

    static func suggestSync(_ photo: Data) -> ItemSuggestion {
        var suggestion = ItemSuggestion()
        guard let image = ImageScaler.downscaledImage(from: photo, maxPixelSize: 600) else { return suggestion }

        let pixels = Pixels(image)
        suggestion.exactColour = pixels.flatMap(dominantColour(in:))

        let labels = classify(image)
        suggestion.labels = labels.map(\.identifier)
        if let rule = labels.lazy.compactMap({ Self.rules[$0.identifier] }).first {
            suggestion.category = rule.category
            suggestion.warmth = rule.warmth
            suggestion.formality = rule.formality
            suggestion.comfort = rule.comfort
        } else if labels.contains(where: { $0.identifier == "clothing" }), let pixels {
            // Vision has no plain "shirt" or "trousers": a tall, narrow garment is a bottom.
            suggestion.category = pixels.subjectAspectRatio > 1.3 ? .bottom : .top
            suggestion.warmth = 3
            suggestion.formality = 3
            suggestion.comfort = 3
        }
        if let warmth = suggestion.warmth {
            suggestion.seasons = seasons(forWarmth: warmth)
        }
        return suggestion
    }

    // MARK: Type

    struct Rule {
        let category: QuickdressCore.Category
        let warmth: Int, formality: Int, comfort: Int
    }

    /// Vision labels that name a garment, with a sensible starting point for each rating.
    static let rules: [String: Rule] = [
        "jacket": Rule(category: .outerwear, warmth: 4, formality: 3, comfort: 3),
        "lab_coat": Rule(category: .outerwear, warmth: 3, formality: 3, comfort: 3),
        "suit": Rule(category: .outerwear, warmth: 3, formality: 5, comfort: 2),
        "tuxedo": Rule(category: .outerwear, warmth: 3, formality: 5, comfort: 2),
        "military_uniform": Rule(category: .outerwear, warmth: 4, formality: 4, comfort: 2),
        "hoodie": Rule(category: .top, warmth: 4, formality: 1, comfort: 5),
        "polo": Rule(category: .top, warmth: 2, formality: 3, comfort: 4),
        "kimono": Rule(category: .top, warmth: 2, formality: 3, comfort: 4),
        "swimsuit": Rule(category: .top, warmth: 1, formality: 1, comfort: 4),
        "jeans": Rule(category: .bottom, warmth: 3, formality: 2, comfort: 3),
        "sneaker": Rule(category: .shoes, warmth: 3, formality: 1, comfort: 5),
        "loafer": Rule(category: .shoes, warmth: 3, formality: 4, comfort: 3),
        "boot": Rule(category: .shoes, warmth: 4, formality: 3, comfort: 3),
        "sandal": Rule(category: .shoes, warmth: 1, formality: 1, comfort: 5),
        "high_heel": Rule(category: .shoes, warmth: 2, formality: 5, comfort: 1),
        "shoes": Rule(category: .shoes, warmth: 3, formality: 3, comfort: 3),
        "footwear": Rule(category: .shoes, warmth: 3, formality: 3, comfort: 3),
        "hat": Rule(category: .accessory, warmth: 3, formality: 2, comfort: 4),
        "baseball_hat": Rule(category: .accessory, warmth: 2, formality: 1, comfort: 5),
        "sunhat": Rule(category: .accessory, warmth: 1, formality: 2, comfort: 4),
        "scarf": Rule(category: .accessory, warmth: 4, formality: 3, comfort: 4),
        "glove": Rule(category: .accessory, warmth: 5, formality: 2, comfort: 4),
        "necktie": Rule(category: .accessory, warmth: 3, formality: 5, comfort: 3),
        "bowtie": Rule(category: .accessory, warmth: 3, formality: 5, comfort: 3),
        "bag": Rule(category: .accessory, warmth: 3, formality: 3, comfort: 4),
        "backpack": Rule(category: .accessory, warmth: 3, formality: 1, comfort: 4),
        "sunglasses": Rule(category: .accessory, warmth: 2, formality: 2, comfort: 4),
        "watch": Rule(category: .accessory, warmth: 3, formality: 3, comfort: 4),
        "jewelry": Rule(category: .accessory, warmth: 3, formality: 4, comfort: 4),
    ]

    static func classify(_ image: CGImage) -> [VNClassificationObservation] {
        let request = VNClassifyImageRequest()
        do {
            try VNImageRequestHandler(cgImage: image).perform([request])
        } catch {
            logger.error("Classification failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
        return (request.results ?? []).filter { $0.confidence >= 0.3 }
    }

    static func seasons(forWarmth warmth: Int) -> Set<Season> {
        switch warmth {
        case ...1: return [.summer]
        case 2: return [.spring, .summer]
        case 3: return [.spring, .autumn]
        case 4: return [.autumn, .winter]
        default: return [.winter]
        }
    }

    // MARK: Colour

    /// The colour of the largest group of similar pixels in the garment, ignoring the
    /// transparent background of a cut-out (or the outer edge of an uncut photo).
    static func dominantColour(in pixels: Pixels) -> RGB? {
        let samples = pixels.subjectSamples
        guard samples.count >= 20 else { return nil }
        var centres = [samples[0], samples[samples.count / 2], samples[samples.count - 1]]
        var groups = [[SIMD3<Double>]](repeating: [], count: centres.count)
        for _ in 0..<10 {
            groups = [[SIMD3<Double>]](repeating: [], count: centres.count)
            for sample in samples {
                let nearest = centres.indices.min { distance(sample, centres[$0]) < distance(sample, centres[$1]) } ?? 0
                groups[nearest].append(sample)
            }
            for index in centres.indices where !groups[index].isEmpty {
                centres[index] = groups[index].reduce(.zero, +) / Double(groups[index].count)
            }
        }
        guard let largest = groups.indices.max(by: { groups[$0].count < groups[$1].count }) else { return nil }
        let centre = centres[largest]
        return RGB(centre.x, centre.y, centre.z)
    }

    private static func distance(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
        let d = a - b
        return (d * d).sum()
    }
}

/// A small RGBA copy of an image, for reading colours.
struct Pixels {
    let width: Int, height: Int
    private let data: [UInt8]
    let hasTransparency: Bool

    init?(_ image: CGImage, side: Int = 64) {
        let scale = Double(side) / Double(max(image.width, image.height))
        let width = max(1, Int(Double(image.width) * scale))
        let height = max(1, Int(Double(image.height) * scale))
        self.width = width
        self.height = height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = buffer.withUnsafeMutableBytes { raw -> Bool in
            guard let context = CGContext(
                data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        data = buffer
        hasTransparency = stride(from: 3, to: buffer.count, by: 4).contains { buffer[$0] < 200 }
    }

    private func alpha(_ x: Int, _ y: Int) -> UInt8 { data[(y * width + x) * 4 + 3] }

    /// Opaque pixels of the garment, as unpremultiplied RGB from 0 to 1. For a photo without
    /// transparency, only the middle 60% is used so the background around it is left out.
    var subjectSamples: [SIMD3<Double>] {
        var samples: [SIMD3<Double>] = []
        let inset = hasTransparency ? 0 : 0.2
        let x0 = Int(Double(width) * inset), x1 = width - x0
        let y0 = Int(Double(height) * inset), y1 = height - y0
        for y in y0..<y1 {
            for x in x0..<x1 {
                let i = (y * width + x) * 4
                let a = Double(data[i + 3])
                guard a >= 230 else { continue }
                samples.append(SIMD3(Double(data[i]) / a, Double(data[i + 1]) / a, Double(data[i + 2]) / a))
            }
        }
        return samples
    }

    /// Height divided by width of the opaque area.
    var subjectAspectRatio: Double {
        guard hasTransparency else { return Double(height) / Double(width) }
        var minX = width, maxX = 0, minY = height, maxY = 0
        for y in 0..<height {
            for x in 0..<width where alpha(x, y) >= 230 {
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY else { return 1 }
        return Double(maxY - minY + 1) / Double(maxX - minX + 1)
    }
}
