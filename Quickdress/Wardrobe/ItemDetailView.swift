import SwiftUI
import UIKit
import QuickdressCore

/// One garment with its receipt, and a menu to edit or delete it.
struct ItemDetailView: View {
    /// The item as it was when the page opened. The page shows the wardrobe's current copy,
    /// so an edit shows up here as soon as it is saved.
    let opened: ClothingItem
    let wardrobe: WardrobeViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var editingModel: CheckInViewModel?
    @State private var confirmDelete = false
    @State private var deleteFailed = false

    init(item: ClothingItem, wardrobe: WardrobeViewModel) {
        self.opened = item
        self.wardrobe = wardrobe
    }

    private var item: ClothingItem {
        wardrobe.items.first { $0.id == opened.id } ?? opened
    }

    private var photo: Data? { wardrobe.photo(for: item) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                GarmentView(
                    image: photo.flatMap(UIImage.init(data:)),
                    isCutOut: photo?.starts(with: [0x89, 0x50, 0x4E, 0x47]) ?? false,
                    tagText: item.tagText,
                    tagColour: item.category.tagColour
                )
                .frame(height: 280)
                .padding(.horizontal, 40)
                .padding(.top, 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: "\(item.accessibilityName), \(item.tagText)"))
                PrinterSlot().padding(.top, 14)
                Receipt {
                    ReceiptHeader(text: "QUICKDRESS · \(item.tagText.uppercased())")
                    ReceiptLine(name: String(localized: "Category")) { Text(item.category.displayName) }
                        .accessibilityElement(children: .combine)
                    ReceiptLine(name: String(localized: "Colour")) {
                        HStack(spacing: 8) {
                            Circle().fill(item.swatch).frame(width: 17, height: 17)
                                .overlay(Circle().strokeBorder(Theme.ink.opacity(0.2)))
                            Text(item.colour.displayName)
                            if let exact = item.exactColour {
                                Text(exact)
                                    .font(.ticket(11.5, relativeTo: .caption))
                                    .foregroundStyle(Theme.secondaryInk)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    levelLine(String(localized: "Warmth"), item.warmth)
                    levelLine(String(localized: "Formality"), item.formality)
                    levelLine(String(localized: "Comfort"), item.comfort)
                    ReceiptLine(name: String(localized: "Season")) { Text(seasonsText) }
                        .accessibilityElement(children: .combine)
                }
                .padding(.top, -3)
                .padding(.bottom, 24)
            }
        }
        .background(Theme.ground)
        .navigationTitle(item.tagText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.ground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(item.tagText)
                    .font(.statement(29, relativeTo: .headline))
                    .foregroundStyle(Theme.ink)
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        editingModel = CheckInViewModel(item: item, manager: wardrobe.manager)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.ink)
                }
                .accessibilityLabel("Edit or delete")
            }
        }
        .sheet(item: $editingModel) { model in
            CheckInView(
                model: model,
                onRetake: nil,
                onFinish: { editingModel = nil }
            )
        }
        .confirmationDialog(
            "Delete this piece?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteItem()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Couldn't delete this piece", isPresented: $deleteFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("It is still in your wardrobe. Try again.")
        }
    }

    private func levelLine(_ name: String, _ value: Int) -> some View {
        ReceiptLine(name: name) { LevelSquares(value: value) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(name)
            .accessibilityValue(String(localized: "\(value) of 5"))
    }

    private var seasonsText: String {
        Season.allCases
            .filter { item.seasons.contains($0) }
            .map(\.displayName)
            .joined(separator: ", ")
    }

    private func deleteItem() {
        do {
            try wardrobe.manager.delete(item)
            dismiss()
        } catch {
            deleteFailed = true
        }
    }
}
