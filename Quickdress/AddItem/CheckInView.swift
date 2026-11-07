import SwiftUI
import UIKit
import QuickdressCore

/// The "New item" and "Edit item" screen: the tagged garment, then one paper card per detail (FR-02, FR-03).
/// Details the app filled in on its own (FR-13) are already set; the user checks them and saves.
struct CheckInView: View {
    @Bindable var model: CheckInViewModel
    /// Nil when editing an item that is already in the wardrobe: its photo is kept.
    var onRetake: (() -> Void)? = nil
    let onFinish: () -> Void

    @State private var confirmDiscard = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    garment
                    if model.isNewItem && !model.suggested.isEmpty {
                        Text("Filled in on this phone. Check each answer before you save.")
                            .font(.ticket(12.5, relativeTo: .footnote))
                            .foregroundStyle(Theme.secondaryInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    categoryCard
                    colourCard
                    levelsCard
                    seasonCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 28)
            }
            .background(Theme.ground)
            .navigationTitle(model.isNewItem ? "New item" : "Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.ground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(model.isNewItem ? "New item" : "Edit item")
                        .font(.statement(27, relativeTo: .headline))
                        .foregroundStyle(Theme.ink)
                        .accessibilityAddTraits(.isHeader)
                }
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
        .tint(Theme.ink)
        .sensoryFeedback(.success, trigger: model.saved?.id)
    }

    // MARK: Garment

    /// The photo with its numbered tag, the same way it appears in the wardrobe.
    private var garment: some View {
        VStack(spacing: 6) {
            ZStack {
                GarmentView(
                    image: model.displayImage,
                    isCutOut: model.showsCutOut,
                    tagText: model.tagText,
                    tagColour: model.category?.tagColour ?? Theme.blankTag
                )
                .frame(height: 290)
                .padding(.horizontal, 36)
                if model.isCuttingOut {
                    VStack(spacing: 6) {
                        ProgressView()
                        Text("Cutting it out…")
                            .font(.ticket(13, relativeTo: .subheadline, medium: true))
                        Button("Use the original photo") { model.useOriginal = true }
                            .font(.footnote)
                            .underline()
                    }
                    .foregroundStyle(Theme.ink)
                    .padding(14)
                    .background(Theme.paper, in: RoundedRectangle(cornerRadius: 4))
                    .shadow(color: Color(red: 0.16, green: 0.13, blue: 0.09).opacity(0.18), radius: 4, y: 3)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(verbatim: "\(String(localized: "Photo of the item")), \(model.tagText)"))

            if let onRetake {
                Button(action: onRetake) {
                    Label("Retake", systemImage: "camera")
                }
                .buttonStyle(UnderlinedButtonStyle())
            }
        }
        .padding(.top, 6)
    }

    // MARK: Category

    private var categoryCard: some View {
        Card(title: "Category", missing: model.category == nil && !model.isPreparing) {
            HStack(spacing: 4) {
                ForEach(QuickdressCore.Category.allCases, id: \.self) { category in
                    let isSelected = model.category == category
                    Button {
                        model.choose(category)
                    } label: {
                        Text(category.displayName)
                            .font(.ticket(11.5, relativeTo: .footnote))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 2)
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(isSelected ? category.tagColour : Color.clear, in: RoundedRectangle(cornerRadius: 3))
                            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Theme.ink, lineWidth: isSelected ? 1.5 : 0))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(3)
            .background(Theme.ground, in: RoundedRectangle(cornerRadius: 4))
        }
    }

    // MARK: Colour

    private var colourCard: some View {
        Card(title: "Colour", detail: colourDetail, missing: model.colour == nil && !model.isPreparing) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(Palette.allCases, id: \.self) { colour in
                    let isSelected = model.colour == colour && model.exactColour == nil
                    Button {
                        model.choose(colour)
                    } label: {
                        Circle()
                            .fill(colour.swatch)
                            .overlay(Circle().strokeBorder(Theme.ink.opacity(0.18)))
                            .frame(width: 32, height: 32)
                            .padding(3)
                            .overlay(Circle().strokeBorder(Theme.ink, lineWidth: isSelected ? 2 : 0))
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu { Text(colour.displayName) }
                    .accessibilityLabel(colour.displayName)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
                ColorPicker(selection: Binding(
                    get: { model.exactColour.map(Color.init(rgb:)) ?? model.colour?.swatch ?? Theme.ink },
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
        if let exact = model.exactColour { return "\(colour.displayName) \(exact.hex)" }
        return colour.displayName
    }

    // MARK: Ratings

    private var levelsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array([CheckInViewModel.Line.warmth, .formality, .comfort].enumerated()), id: \.offset) { index, line in
                if index > 0 { DashedRule().opacity(0.35).padding(.horizontal, 16) }
                LevelRow(
                    title: levelName(line),
                    value: model.level(line),
                    set: { model.setLevel(line, to: $0) },
                    adjust: { model.adjust(line, by: $0) }
                )
            }
        }
        .padding(.vertical, 4)
        .paperCard()
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
        Card(title: "Season", missing: model.seasons.isEmpty && !model.isPreparing) {
            HStack(spacing: 8) {
                ForEach([Season.winter, .spring, .summer, .autumn], id: \.self) { season in
                    let isSelected = model.seasons.contains(season)
                    Button {
                        model.toggle(season)
                    } label: {
                        Text(season.displayName)
                            .font(.ticket(13, relativeTo: .subheadline, medium: isSelected))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(isSelected ? Theme.paper : Theme.ink)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(TagShape().fill(isSelected ? Theme.ink : Theme.ground))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
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

/// A paper card with a statement title and its control underneath.
private struct Card<Content: View>: View {
    let title: LocalizedStringKey
    var detail: String? = nil
    var missing = false
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.statement(25, relativeTo: .title3))
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if missing {
                    Text("Needed")
                        .font(.ticket(12.5, relativeTo: .footnote, medium: true))
                        .foregroundStyle(Theme.stamp)
                } else if let detail {
                    Text(detail)
                        .font(.ticket(12.5, relativeTo: .footnote))
                        .foregroundStyle(Theme.secondaryInk)
                }
            }
            content
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperCard()
    }
}

private extension View {
    /// The receipt paper every card on this screen is printed on.
    func paperCard() -> some View {
        background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.paper)
                .shadow(color: Color(red: 0.16, green: 0.13, blue: 0.09).opacity(0.12), radius: 3, y: 2)
        )
    }
}

/// One rating from 1 to 5, shown as five squares like the receipt. Tap a square to set it.
private struct LevelRow: View {
    let title: String
    let value: Int
    let set: (Int) -> Void
    let adjust: (Int) -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.statement(23, relativeTo: .title3))
                .foregroundStyle(Theme.ink)
            Spacer()
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        set(level)
                    } label: {
                        Rectangle()
                            .fill(level <= value ? Theme.ink : Color.clear)
                            .overlay(Rectangle().strokeBorder(level <= value ? Theme.ink : Color(hex: 0xA9A49B), lineWidth: 1.5))
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
