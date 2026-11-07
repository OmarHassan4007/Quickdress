import SwiftUI
import QuickdressCore

/// Filters by season, warmth, formality and comfort (FR-04, attribute filters).
/// Category and colour stay in the tag rows on the Wardrobe page.
struct WardrobeFilterSheet: View {
    @Bindable var model: WardrobeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Filter by")
                    .font(.statement(31))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Clear") { model.filter.clearAttributes() }
                    .font(.body)
                    .foregroundStyle(model.filter.hasAttributeFilters ? Theme.ink : Theme.secondaryInk)
                    .disabled(!model.filter.hasAttributeFilters)
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    seasonSection
                    ForEach(ClothingItem.Level.allCases, id: \.self) { level in
                        bandSection(level)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }

            Button(showLabel) { dismiss() }
                .buttonStyle(StubButtonStyle())
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.ground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.ground)
        .presentationCornerRadius(22)
    }

    private var showLabel: String {
        let count = model.visibleItems.count
        return count == 1 ? String(localized: "Show 1 piece") : String(localized: "Show \(count) pieces")
    }

    private var seasonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(String(localized: "Season"), note: String(localized: "Any selected season"))
            HStack(spacing: 8) {
                ForEach([Season.winter, .spring, .summer, .autumn], id: \.self) { season in
                    let isSelected = model.filter.seasons.contains(season)
                    Button {
                        if isSelected {
                            model.filter.seasons.remove(season)
                        } else {
                            model.filter.seasons.insert(season)
                        }
                    } label: {
                        Text(season.displayName)
                            .font(.ticket(13, relativeTo: .subheadline, medium: isSelected))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(isSelected ? Theme.paper : Theme.ink)
                            .padding(.leading, 10)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(TagShape().fill(isSelected ? Theme.ink : Theme.paper))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private func bandSection(_ level: ClothingItem.Level) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(level.displayName, note: nil)
            HStack(spacing: 4) {
                bandOption(level, band: nil)
                ForEach(LevelBand.allCases, id: \.self) { band in
                    bandOption(level, band: band)
                }
            }
            .padding(3)
            .background(Theme.paper, in: RoundedRectangle(cornerRadius: 4))
        }
    }

    private func bandOption(_ level: ClothingItem.Level, band: LevelBand?) -> some View {
        let isSelected = model.filter.levels[level] == band
        return Button {
            model.filter.levels[level] = band
        } label: {
            VStack(spacing: 1) {
                Text(band?.displayName ?? String(localized: "Any"))
                    .font(.ticket(12.5, relativeTo: .footnote, medium: isSelected))
                if let band {
                    Text(band.rangeText)
                        .font(.ticket(10.5, relativeTo: .caption2))
                        .opacity(0.75)
                }
            }
            .lineLimit(1)
            .foregroundStyle(isSelected ? Theme.paper : Theme.ink)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(isSelected ? Theme.ink : Color.clear, in: RoundedRectangle(cornerRadius: 3))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(band.map { "\(level.displayName): \($0.displayName), \($0.rangeText)" } ?? "\(level.displayName): \(String(localized: "Any"))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func sectionTitle(_ title: String, note: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.statement(23, relativeTo: .title3))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let note {
                Text(note)
                    .font(.ticket(11.5, relativeTo: .caption))
                    .foregroundStyle(Theme.secondaryInk)
            }
        }
    }
}
