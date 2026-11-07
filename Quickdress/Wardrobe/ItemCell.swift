import SwiftUI
import UIKit
import QuickdressCore

/// One garment in the Wardrobe grid: the cut-out photo with its numbered tag.
struct ItemCell: View {
    let item: ClothingItem
    let loadPhoto: () -> Data?
    @State private var thumbnail: UIImage?
    @State private var isCutOut = false

    init(item: ClothingItem, loadPhoto: @escaping () -> Data?) {
        self.item = item
        self.loadPhoto = loadPhoto
    }

    var body: some View {
        GarmentView(
            image: thumbnail,
            isCutOut: isCutOut,
            tagText: item.tagText,
            tagColour: item.category.tagColour,
            tagScale: 0.78,
            showsString: false
        )
        .aspectRatio(0.92, contentMode: .fit)
        .padding(.bottom, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: item.accessibilityName))
        .task(id: item.photo) {
            let data = loadPhoto()
            isCutOut = data?.starts(with: [0x89, 0x50, 0x4E, 0x47]) ?? false
            thumbnail = await makeThumbnail(from: data)
        }
    }

    private func makeThumbnail(from data: Data?) async -> UIImage? {
        guard let data, let image = UIImage(data: data) else { return nil }
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > 0 else { return nil }
        let scale = 400 / longestSide
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return await image.byPreparingThumbnail(ofSize: size)
    }
}
