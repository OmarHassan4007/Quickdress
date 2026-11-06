import SwiftUI
import UIKit
import QuickdressCore

struct ItemCell: View {
    let item: ClothingItem
    let loadPhoto: () -> Data?
    @State private var thumbnail: UIImage?

    init(item: ClothingItem, loadPhoto: @escaping () -> Data?) {
        self.item = item
        self.loadPhoto = loadPhoto
    }

    var body: some View {
        Color(.secondarySystemBackground)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "tshirt")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: item.accessibilityName))
            .task(id: item.photo) {
                thumbnail = await makeThumbnail()
            }
    }

    private func makeThumbnail() async -> UIImage? {
        guard let data = loadPhoto(), let image = UIImage(data: data) else { return nil }
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > 0 else { return nil }
        let scale = 300 / longestSide
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return await image.byPreparingThumbnail(ofSize: size)
    }
}
