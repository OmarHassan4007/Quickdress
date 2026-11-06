import SwiftUI
import QuickdressCore

extension Category {
    var displayName: String {
        switch self {
        case .top: return String(localized: "Top")
        case .bottom: return String(localized: "Bottom")
        case .outerwear: return String(localized: "Outerwear")
        case .shoes: return String(localized: "Shoes")
        case .accessory: return String(localized: "Accessory")
        }
    }

    var pluralName: String {
        switch self {
        case .top: return String(localized: "Tops")
        case .bottom: return String(localized: "Bottoms")
        case .outerwear: return String(localized: "Outerwear")
        case .shoes: return String(localized: "Shoes")
        case .accessory: return String(localized: "Accessories")
        }
    }
}

extension Palette {
    var displayName: String {
        switch self {
        case .black: return String(localized: "Black")
        case .white: return String(localized: "White")
        case .grey: return String(localized: "Grey")
        case .navy: return String(localized: "Navy")
        case .beige: return String(localized: "Beige")
        case .red: return String(localized: "Red")
        case .pink: return String(localized: "Pink")
        case .orange: return String(localized: "Orange")
        case .yellow: return String(localized: "Yellow")
        case .green: return String(localized: "Green")
        case .blue: return String(localized: "Blue")
        case .purple: return String(localized: "Purple")
        }
    }

    var swatch: Color {
        switch self {
        case .black: return Color(red: 0.08, green: 0.08, blue: 0.08)
        case .white: return Color(red: 1.0, green: 1.0, blue: 1.0)
        case .grey: return Color(red: 0.6, green: 0.6, blue: 0.6)
        case .navy: return Color(red: 0.09, green: 0.14, blue: 0.33)
        case .beige: return Color(red: 0.9, green: 0.84, blue: 0.72)
        case .red: return Color(red: 0.85, green: 0.16, blue: 0.16)
        case .pink: return Color(red: 0.96, green: 0.55, blue: 0.7)
        case .orange: return Color(red: 0.96, green: 0.55, blue: 0.13)
        case .yellow: return Color(red: 0.98, green: 0.84, blue: 0.2)
        case .green: return Color(red: 0.22, green: 0.6, blue: 0.32)
        case .blue: return Color(red: 0.2, green: 0.45, blue: 0.85)
        case .purple: return Color(red: 0.5, green: 0.3, blue: 0.7)
        }
    }
}

extension Season {
    var displayName: String {
        switch self {
        case .spring: return String(localized: "Spring")
        case .summer: return String(localized: "Summer")
        case .autumn: return String(localized: "Autumn")
        case .winter: return String(localized: "Winter")
        }
    }
}

extension ClothingItem {
    var accessibilityName: String {
        String(localized: "\(colour.displayName) \(category.displayName)")
    }
}
