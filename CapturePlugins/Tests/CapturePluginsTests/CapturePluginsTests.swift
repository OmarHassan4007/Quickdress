import XCTest
import CoreGraphics
import UniformTypeIdentifiers
@testable import CapturePlugins
import QuickdressCore

final class ImageScalerTests: XCTestCase {
    private func makePNG(width: Int, height: Int) throws -> Data {
        let context = try XCTUnwrap(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0.1, green: 0.15, blue: 0.3, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try XCTUnwrap(context.makeImage())
        return try XCTUnwrap(ImageScaler.encode(image, as: .png))
    }

    func testLargePhotosAreScaledToTheLongestSideLimit() throws {
        let data = try makePNG(width: 4000, height: 3000)
        let image = try XCTUnwrap(ImageScaler.downscaledImage(from: data))
        XCTAssertEqual(max(image.width, image.height), ImageScaler.maxPixelSize)
        XCTAssertEqual(image.width, 1600)
        XCTAssertEqual(image.height, 1200)
    }

    func testJPEGOutputIsJPEG() throws {
        let jpeg = try XCTUnwrap(ImageScaler.jpegData(from: try makePNG(width: 800, height: 600)))
        XCTAssertTrue(jpeg.starts(with: [0xFF, 0xD8]))
    }

    func testDataThatIsNotAnImageGivesNothing() {
        XCTAssertNil(ImageScaler.jpegData(from: Data("not an image".utf8)))
        XCTAssertNil(SubjectLifter.liftSync(Data("not an image".utf8)))
    }
}

final class SubjectLifterTests: XCTestCase {
    func testAGarmentPhotographedOnABedIsCutOut() async throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "overshirt-on-bed", withExtension: "jpg", subdirectory: "Fixtures"))
        let photo = try Data(contentsOf: url)

        let lifted = await SubjectLifter().lift(photo)
        let cutOut = try XCTUnwrap(lifted)

        XCTAssertTrue(cutOut.starts(with: [0x89, 0x50, 0x4E, 0x47]), "the cut-out is a PNG")
        let image = try XCTUnwrap(ImageScaler.downscaledImage(from: cutOut))
        XCTAssertTrue([.premultipliedLast, .last, .premultipliedFirst, .first].contains(image.alphaInfo), "the cut-out keeps transparency")
        XCTAssertLessThan(image.width * image.height, 700 * 525, "the cut-out is cropped to the garment")
    }
}

final class ItemAnalyzerTests: XCTestCase {
    func testTheOvershirtIsSuggestedAsNavyOuterwear() async throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "overshirt-on-bed", withExtension: "jpg", subdirectory: "Fixtures"))
        let lifted = await SubjectLifter().lift(try Data(contentsOf: url))
        let cutOut = try XCTUnwrap(lifted)

        let suggestion = await ItemAnalyzer().suggest(for: cutOut)

        XCTAssertEqual(suggestion.category, .outerwear, "labels: \(suggestion.labels)")
        XCTAssertEqual(suggestion.colour, .navy, "measured \(suggestion.exactColour?.hex ?? "nothing")")
        XCTAssertEqual(suggestion.warmth, 4)
        XCTAssertEqual(suggestion.seasons, [.autumn, .winter])
    }

    func testTheColourOfAPlainImageIsMeasured() throws {
        let context = try XCTUnwrap(CGContext(
            data: nil, width: 120, height: 120, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(srgbRed: 0.85, green: 0.16, blue: 0.16, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 120, height: 120))
        let pixels = try XCTUnwrap(Pixels(try XCTUnwrap(context.makeImage())))

        let colour = try XCTUnwrap(ItemAnalyzer.dominantColour(in: pixels))

        XCTAssertEqual(Palette.nearest(to: colour), .red)
    }

    func testSeasonsFollowWarmth() {
        XCTAssertEqual(ItemAnalyzer.seasons(forWarmth: 1), [.summer])
        XCTAssertEqual(ItemAnalyzer.seasons(forWarmth: 3), [.spring, .autumn])
        XCTAssertEqual(ItemAnalyzer.seasons(forWarmth: 5), [.winter])
    }
}
