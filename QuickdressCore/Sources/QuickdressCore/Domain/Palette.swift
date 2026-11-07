import Foundation

public enum Palette: String, CaseIterable, Codable, Sendable {
    case black
    case white
    case grey
    case navy
    case beige

    case red
    case pink
    case orange
    case yellow
    case green
    case blue
    case purple

    public var isNeutral: Bool {
        switch self {
        case .black, .white, .grey, .navy, .beige:
            return true
        case .red, .pink, .orange, .yellow, .green, .blue, .purple:
            return false
        }
    }

    /// The reference colour of each palette entry, in sRGB from 0 to 1. These are tuned to how
    /// real garments photograph (a navy jacket is much darker and greyer than a paint-chip navy),
    /// so measured colours land on the right name. They are for matching, not for display.
    public var rgb: RGB {
        switch self {
        case .black: return RGB(0.08, 0.08, 0.08)
        case .white: return RGB(0.96, 0.96, 0.95)
        case .grey: return RGB(0.64, 0.64, 0.64)
        case .navy: return RGB(0.11, 0.13, 0.22)
        case .beige: return RGB(0.86, 0.79, 0.66)
        case .red: return RGB(0.75, 0.15, 0.15)
        case .pink: return RGB(0.93, 0.58, 0.68)
        case .orange: return RGB(0.92, 0.5, 0.15)
        case .yellow: return RGB(0.95, 0.82, 0.25)
        case .green: return RGB(0.22, 0.5, 0.3)
        case .blue: return RGB(0.2, 0.42, 0.75)
        case .purple: return RGB(0.45, 0.28, 0.6)
        }
    }

    /// Every reference point for this colour. Grey covers a wide range, from charcoal
    /// to light grey, so it has two.
    var references: [RGB] {
        switch self {
        case .grey: return [rgb, RGB(0.38, 0.38, 0.39)]
        // Second points for how these colours come out in photos of real garments
        // (measured on the Sprint 1 test photos): faded denim, khaki chinos, dark knitwear.
        case .blue: return [rgb, RGB(0.29, 0.40, 0.52)]
        case .beige: return [rgb, RGB(0.70, 0.61, 0.49)]
        case .green: return [rgb, RGB(0.10, 0.22, 0.15)]
        default: return [rgb]
        }
    }

    /// The palette colour closest to an exact colour, measured in CIE Lab so the
    /// distance matches how different the colours look.
    public static func nearest(to colour: RGB) -> Palette {
        let target = colour.lab
        func distance(_ palette: Palette) -> Double {
            palette.references.map { $0.lab.distance(to: target) }.min() ?? .infinity
        }
        return allCases.min { distance($0) < distance($1) } ?? .grey
    }
}

/// An exact colour in sRGB, each channel from 0 to 1.
public struct RGB: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(_ red: Double, _ green: Double, _ blue: Double) {
        self.red = min(1, max(0, red))
        self.green = min(1, max(0, green))
        self.blue = min(1, max(0, blue))
    }

    /// "#1E2A4C".
    public var hex: String {
        String(format: "#%02X%02X%02X", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }

    public init?(hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        self.init(Double((value >> 16) & 0xFF) / 255, Double((value >> 8) & 0xFF) / 255, Double(value & 0xFF) / 255)
    }

    struct Lab {
        let l: Double, a: Double, b: Double
        func distance(to other: Lab) -> Double {
            let dl = l - other.l, da = a - other.a, db = b - other.b
            return (dl * dl + da * da + db * db).squareRoot()
        }
    }

    var lab: Lab {
        func linear(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        let r = linear(red), g = linear(green), b = linear(blue)
        let x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
        let y = 0.2126 * r + 0.7152 * g + 0.0722 * b
        let z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
        func f(_ t: Double) -> Double { t > 0.008856 ? cbrt(t) : 7.787 * t + 16 / 116 }
        let fx = f(x), fy = f(y), fz = f(z)
        return Lab(l: 116 * fy - 16, a: 500 * (fx - fy), b: 200 * (fy - fz))
    }
}
