import SwiftUI
import UIKit
import QuickdressCore

/// The "New item" screen: the photo, then one card per detail (FR-02).
/// Details the app filled in on its own (FR-13) are already set; the user checks them and saves.
struct CheckInView: View {
    @Bindable var model: CheckInViewModel
    let onRetake: () -> Void
    let onFinish: () -> Void

    @State private var confirmDiscard = false

    private let cardFill = Color(hex: 0xF2F2F4)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    photoCard
                    if !model.suggested.isEmpty {
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
            .navigationTitle("New item")
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
            .confirmationDialog("Discard this item?", isPresented: $confirmDiscard, titleVisibility: .visible) {
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
            .accessibilityLabel("Photo of the new item")

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
        .padding(.bottom, 14)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: Category

    private var categoryCard: some View {
        Card(title: "Category", missing: model.category == nil && !model.isPreparing, fill: cardFill) {
            HStack(spacing: 0) {
                ForEach(QuickdressCore.Category.allCases, id: \.self) { category in
                    let isSelected = model.category == category
                    Button {
                        model.choose(category)
                    } label: {
                        Text(category.displayName)
                            .font(.footnote)
                            .lineLimit(1)
                            .fixedSize()
                            .foregroundStyle(isSelected ? Color.white : Color.black)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(isSelected ? Color.black : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(3)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: Colour

    private var colourCard: some View {
        Card(title: "Colour", detail: colourDetail, missing: model.colour == nil && !model.isPreparing, fill: cardFill) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(Palette.allCases, id: \.self) { colour in
                    let isSelected = model.colour == colour && model.exactColour == nil
                    Button {
                        model.choose(colour)
                    } label: {
                        Circle()
                            .fill(colour.swatch)
                            .overlay(Circle().strokeBorder(Color.black.opacity(0.12)))
                            .frame(width: 32, height: 32)
                            .padding(3)
                            .overlay(Circle().strokeBorder(Color.black, lineWidth: isSelected ? 2 : 0))
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu { Text(colour.displayName) }
                    .accessibilityLabel(colour.displayName)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
                ColorPicker(selection: Binding(
                    get: { model.exactColour.map(Color.init(rgb:)) ?? model.colour?.swatch ?? .black },
                    set: { model.chooseExact(RGB(colour: $0)) }
                ), supportsOpacity: false) {
                    Text("Exact colour")
                }
                .labelsHidden()
                .scaleEffect(1.3)
                .frame(width: 44, height: 44)
                .accessibilityLabel("Exact colour, with a colour wheel and an eyedropper")
            }
        }
    }

    private var colourDetail: String? {
        guard let colour = model.colour else { return nil }
        if let exact = model.exactColour { return "\(colour.displayName) · \(exact.hex)" }
        return colour.displayName
    }

    // MARK: Ratings

    private var levelsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array([CheckInViewModel.Line.warmth, .formality, .comfort].enumerated()), id: \.offset) { index, line in
                if index > 0 { Divider().padding(.leading, 16) }
                LevelRow(
                    title: levelName(line),
                    value: model.level(line),
                    set: { model.setLevel(line, to: $0) },
                    adjust: { model.adjust(line, by: $0) }
                )
            }
        }
        .padding(.vertical, 4)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 18))
    }

    private func levelName(_ line: CheckInViewModel.Line) -> String {
        switch line {
        case .warmth: return String(localized: "Warmth")
        case .formality: return String(localized: "Formality")
        default: return String(localized: "Comfort")
        }
    }

    // MARK: Season

    private var seasonCard: some View {
        Card(title: "Season", missing: model.seasons.isEmpty && !model.isPreparing, fill: cardFill) {
            HStack(spacing: 8) {
                ForEach([Season.winter, .spring, .summer, .autumn], id: \.self) { season in
                    let isSelected = model.seasons.contains(season)
                    Button {
                        model.toggle(season)
                    } label: {
                        Text(season.displayName)
                            .font(.body)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .foregroundStyle(isSelected ? Color.white : Color.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(isSelected ? Color.black : Color.white, in: Capsule())
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

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
