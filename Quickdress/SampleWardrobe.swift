import SwiftUI
import UIKit
import QuickdressCore

@MainActor
enum SampleWardrobe {
    /// One piece in a demo wardrobe folder's `demo.json` (debug builds, `-demoPhotos <folder>`).
    private struct DemoPiece: Decodable {
        let file: String
        let category: QuickdressCore.Category
        let colour: Palette
        let exactColour: String?
        let warmth: Int
        let formality: Int
        let comfort: Int
        let seasons: Set<Season>
    }

    /// Fills an empty wardrobe with real photographed pieces from a folder, for demos and screenshots.
    static func addDemoIfEmpty(from folder: URL, to manager: WardrobeManager) {
        guard (try? manager.allItems().isEmpty) == true,
              let manifest = try? Data(contentsOf: folder.appendingPathComponent("demo.json")),
              let pieces = try? JSONDecoder().decode([DemoPiece].self, from: manifest) else { return }
        for piece in pieces {
            guard let photo = try? Data(contentsOf: folder.appendingPathComponent(piece.file)) else { continue }
            let item = ClothingItem(
                category: piece.category, colour: piece.colour,
                warmth: piece.warmth, formality: piece.formality, comfort: piece.comfort,
                seasons: piece.seasons, exactColour: piece.exactColour
            )
            try? manager.addItem(item, photo: photo)
        }
    }

    static func addIfEmpty(to manager: WardrobeManager) {
        guard (try? manager.allItems().isEmpty) == true else { return }
        for item in items {
            try? manager.addItem(item, photo: photo(for: item.colour))
        }
    }

    private static var items: [ClothingItem] {
        [
            ClothingItem(category: .top, colour: .white, warmth: 2, formality: 3, comfort: 4, seasons: [.spring, .summer]),
            ClothingItem(category: .top, colour: .navy, warmth: 3, formality: 4, comfort: 3, seasons: [.autumn, .winter]),
            ClothingItem(category: .top, colour: .red, warmth: 2, formality: 2, comfort: 5, seasons: [.summer]),
            ClothingItem(category: .bottom, colour: .beige, warmth: 3, formality: 3, comfort: 4, seasons: [.spring, .autumn]),
            ClothingItem(category: .bottom, colour: .blue, warmth: 3, formality: 2, comfort: 4, seasons: [.spring, .summer, .autumn, .winter]),
            ClothingItem(category: .outerwear, colour: .grey, warmth: 5, formality: 3, comfort: 3, seasons: [.winter]),
            ClothingItem(category: .shoes, colour: .black, warmth: 3, formality: 4, comfort: 3, seasons: [.autumn, .winter]),
            ClothingItem(category: .shoes, colour: .white, warmth: 2, formality: 1, comfort: 5, seasons: [.spring, .summer]),
            ClothingItem(category: .accessory, colour: .green, warmth: 3, formality: 2, comfort: 5, seasons: [.autumn]),
        ]
    }

    private static func photo(for colour: Palette) -> Data {
        let size = CGSize(width: 600, height: 600)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(colour.swatch).setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }
}
