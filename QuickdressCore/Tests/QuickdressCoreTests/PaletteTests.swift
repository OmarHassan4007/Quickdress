import XCTest
import QuickdressCore

final class PaletteTests: XCTestCase {
    func testExactColoursMapToTheNearestPaletteColour() {
        XCTAssertEqual(Palette.nearest(to: RGB(0.12, 0.16, 0.30)), .navy, "a dark washed navy")
        XCTAssertEqual(Palette.nearest(to: RGB(0.96, 0.95, 0.92)), .white, "an off-white shirt")
        XCTAssertEqual(Palette.nearest(to: RGB(0.82, 0.74, 0.60)), .beige, "a stone chino")
        XCTAssertEqual(Palette.nearest(to: RGB(0.70, 0.10, 0.12)), .red, "a dark red")
        XCTAssertEqual(Palette.nearest(to: RGB(0.35, 0.35, 0.36)), .grey, "charcoal is grey, not black")
        XCTAssertEqual(Palette.nearest(to: RGB(0.02, 0.02, 0.03)), .black)
        XCTAssertEqual(Palette.nearest(to: RGB(hex: "#272B38")!), .navy, "the overshirt as photographed")
        XCTAssertEqual(Palette.nearest(to: RGB(hex: "#242733")!), .navy, "the overshirt measured from the uncut photo")
        XCTAssertEqual(Palette.nearest(to: RGB(hex: "#18181A")!), .black, "a black tee as photographed")
        XCTAssertEqual(Palette.nearest(to: RGB(hex: "#2B2B30")!), .black, "a faded black")
        XCTAssertEqual(Palette.nearest(to: RGB(hex: "#C8C8C8")!), .grey, "light grey is still grey")
        XCTAssertEqual(Palette.nearest(to: RGB(hex: "#3A5A8C")!), .blue, "mid denim blue")
    }

    func testEveryPaletteColourMapsToItself() {
        for colour in Palette.allCases {
            XCTAssertEqual(Palette.nearest(to: colour.rgb), colour)
        }
    }

    func testHexRoundTrips() {
        XCTAssertEqual(RGB(hex: "#1E2A4C")?.hex, "#1E2A4C")
        XCTAssertEqual(RGB(hex: "1e2a4c")?.hex, "#1E2A4C")
        XCTAssertNil(RGB(hex: "#12345"))
    }
}
