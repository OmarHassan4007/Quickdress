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
}
