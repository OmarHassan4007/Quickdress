import SwiftUI
import UIKit
import QuickdressCore

struct ItemDetailView: View {
    let item: ClothingItem
    let photo: Data?

    var body: some View {
        List {
            if let photo, let image = UIImage(data: photo) {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(Text(verbatim: item.accessibilityName))
                }
            }
            Section {
                LabeledContent("Category", value: item.category.displayName)
                LabeledContent("Colour", value: item.colour.displayName)
                LabeledContent("Warmth", value: levelText(item.warmth))
                LabeledContent("Formality", value: levelText(item.formality))
                LabeledContent("Comfort", value: levelText(item.comfort))
                LabeledContent("Seasons", value: seasonsText)
            }
        }
        .navigationTitle(item.category.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func levelText(_ level: Int) -> String {
        String(localized: "\(level) of 5")
    }

    private var seasonsText: String {
        Season.allCases
            .filter { item.seasons.contains($0) }
            .map(\.displayName)
            .formatted(.list(type: .and))
    }
}
