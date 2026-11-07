import SwiftUI
import UIKit
import QuickdressCore

/// The "New item" screen: the photo, then one card per detail (FR-02).
/// Details the app filled in on its own (FR-13) are already set; the user checks them and saves.
struct CheckInView: View {
    @Bindable var model: CheckInViewModel
    /// Optional when editing existing items where camera retake isn't applicable
    var onRetake: (() -> Void)? = nil
    let onFinish: () -> Void

    @State private var confirmDiscard = false

    private let cardFill = Color(hex: 0xF2F2F4)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    photoCard
                    
                    // Show only during new item creation/auto-tagging
                    if model.isNewItem && !model.suggested.isEmpty {
                        Text("Filled in on this phone. Check each answer before you save.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 6)
                    }
                    categoryCard
                    colourCard
                    levelsCard
                    seasonCard
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .background(Color.white)
            .navigationTitle(model.isNewItem ? "New item" : "Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { confirmDiscard = true }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .disabled(!model.canSave)
                }
            }
            .confirmationDialog(
                model.isNewItem ? "Discard this item?" : "Discard changes?",
                isPresented: $confirmDiscard,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive, action: onFinish)
                Button("Keep editing", role: .cancel) {}
            }
            .alert("Couldn't save this item", isPresented: Binding(
                get: { model.saveError != nil },
                set: { if !$0 { model.saveError = nil } }
            )) {
                Button("Try Again") { save() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(model.saveError ?? "")
            }
        }
        .tint(.black)
        .sensoryFeedback(.success, trigger: model.saved?.id)
    }

    // MARK: Photo

    private var photoCard: some View {
        VStack(spacing: 12) {
            ZStack {
                if let image = model.displayImage {
                    if model.showsCutOut {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(18)
                            .shadow(color: .black.opacity(0.18), radius: 8, y: 6)
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                if model.isCuttingOut {
                    VStack(spacing: 6) {
                        ProgressView()
                        Text("Cutting it out…").font(.subheadline.weight(.medium))
                        Button("Use the original photo") { model.useOriginal = true }
                            .font(.footnote)
                            .underline()
                    }
                    .padding(14)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Photo of the item")

            if let onRetake {
                Button(action: onRetake) {
                    Label("Retake", systemImage: "camera")
                        .font(.body)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 22)
                        .frame(minHeight: 40)
                        .background(Color(hex: 0xE5E5EA), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 14)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: Remaining View code (categoryCard, colourCard, levelsCard, seasonCard) unchanged...

    private func save() {
        if model.save() {
            onFinish()
        }
    }
}

/// A grey card with a bold title and its control underneath.
private struct Card<Content: View>: View {
    let title: LocalizedStringKey
    var detail: String? = nil
    var missing = false
    let fill: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if missing {
                    Text("Needed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if let detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill, in: RoundedRectangle(cornerRadius: 18))
    }
}

/// One rating from 1 to 5, shown as five dots. Tap a dot to set it.
private struct LevelRow: View {
    let title: String
    let value: Int
    let set: (Int) -> Void
    let adjust: (Int) -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
            Spacer()
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        set(level)
                    } label: {
                        Circle()
                            .fill(level <= value ? Color.black : Color.clear)
                            .overlay(Circle().strokeBorder(level <= value ? Color.black : Color(hex: 0xBDBDC2), lineWidth: 1.5))
                            .frame(width: 18, height: 18)
                            .frame(width: 36, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(String(localized: "\(value) of 5"))
        .accessibilityAdjustableAction { direction in
            adjust(direction == .increment ? 1 : -1)
        }
    }
}
