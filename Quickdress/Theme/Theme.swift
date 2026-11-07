import SwiftUI
import UIKit
import CoreText
import QuickdressCore

/// The claim-ticket look: colours, type and the category tag colours.
/// See Design/Add item interface, section 1.
enum Theme {
    static let ground = Color(hex: 0xF3F1EC)
    static let ink = Color(hex: 0x141414)
    static let secondaryInk = Color(hex: 0x57534C)
    static let paper = Color(hex: 0xFCFBF8)
    static let stamp = Color(hex: 0xC2185B)
    static let buttonOff = Color(hex: 0xD9D5CD)
    static let buttonOffInk = Color(hex: 0x5F5B54)
    static let blankTag = Color(hex: 0xFCFBF8)
    static let rule = Color(hex: 0xD8D4CC)
    static let string = Color(hex: 0xB59E70)

    /// Registers the bundled fonts once at launch.
    static func registerFonts() {
        for name in ["PragatiNarrow-Bold", "ChivoMono-Regular", "ChivoMono-Medium"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

}

extension Font {
    /// Statements: titles, the stub label, sheet headings, text buttons.
    static func statement(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom("PragatiNarrow-Bold", size: size, relativeTo: style)
    }

    /// Ticket text: everything printed on a receipt, tag or ticket.
    static func ticket(_ size: CGFloat, relativeTo style: Font.TextStyle = .body, medium: Bool = false) -> Font {
        .custom(medium ? "ChivoMono-Medium" : "ChivoMono-Regular", size: size, relativeTo: style)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension QuickdressCore.Category {
    /// The tag colour for this category, the same on every screen.
    var tagColour: Color {
        switch self {
        case .top: return Color(hex: 0xBDE8D2)
        case .bottom: return Color(hex: 0xF7B9C8)
        case .outerwear: return Color(hex: 0xBFD9F2)
        case .shoes: return Color(hex: 0xD9C6F0)
        case .accessory: return Color(hex: 0xF9C9A6)
        }
    }
}

extension ClothingItem {
    /// "No. 032".
    var tagText: String { Self.tagText(number) }

    static func tagText(_ number: Int) -> String {
        String(format: "No. %03d", number)
    }
}

extension Image {
    /// An image shipped as a loose file in the app bundle (the stamp images).
    static func bundled(_ name: String) -> Image {
        if let image = UIImage(named: name) {
            return Image(uiImage: image)
        }
        return Image(systemName: "seal")
    }
}

extension Color {
    init(rgb: RGB) {
        self.init(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}

extension RGB {
    /// The colour the user picked with the colour wheel or eyedropper.
    init(colour: Color) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(colour).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(Double(red), Double(green), Double(blue))
    }
}

extension ClothingItem {
    /// The exact colour when there is one, otherwise the palette colour.
    var swatch: Color {
        exactColour.flatMap(RGB.init(hex:)).map(Color.init(rgb:)) ?? colour.swatch
    }
}
