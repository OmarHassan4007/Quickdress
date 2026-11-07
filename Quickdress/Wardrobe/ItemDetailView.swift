import SwiftUI
import UIKit
import QuickdressCore

/// One garment with its receipt (read/write operations included).
struct ItemDetailView: View {
    let item: ClothingItem
    let photo: Data?
    let manager: WardrobeManager
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var editingModel: CheckInViewModel?
    @State private var confirmDelete = false

    init(
        item: ClothingItem,
        photo: Data?,
        manager: WardrobeManager,
        onDelete: (() -> Void)? = nil
    ) {
        self.item = item
        self.photo = photo
        self.manager = manager
        self.onDelete = onDelete
    }

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
                        editingModel = CheckInViewModel(item: item, manager: manager)
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
        if let onDelete {
            onDelete()
        } else {
            try? manager.deleteItem(item)
        }
        dismiss()
    }
}