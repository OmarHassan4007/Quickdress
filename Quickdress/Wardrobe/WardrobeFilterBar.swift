import SwiftUI
import QuickdressCore

/// Category and colour filters, drawn as paper tags, and the season and rating filters
/// that are on, each removable with a tap (FR-04).
struct WardrobeFilterBar: View {
    @Binding var filter: WardrobeFilter
    let colours: [Palette]
    let showMoreFilters: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: String(localized: "All"), fill: Theme.paper, isSelected: filter.category == nil) {
                        filter.category = nil
                    }
                    ForEach(QuickdressCore.Category.allCases, id: \.self) { category in
                        FilterChip(title: category.pluralName, fill: category.tagColour, isSelected: filter.category == category) {
                            filter.category = filter.category == category ? nil : category
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 3)
            }
            if !colours.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: String(localized: "Any colour"), fill: Theme.paper, isSelected: filter.colour == nil) {
                            filter.colour = nil
                        }
                        ForEach(colours, id: \.self) { colour in
                            FilterChip(title: colour.displayName, swatch: colour.swatch, fill: Theme.paper, isSelected: filter.colour == colour) {
                                filter.colour = filter.colour == colour ? nil : colour
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 3)
                }
            }
            if filter.hasAttributeFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: String(localized: "More filters"), fill: Theme.paper, isSelected: false, action: showMoreFilters)
                        ForEach(Season.allCases.filter { filter.seasons.contains($0) }, id: \.self) { season in
                            FilterChip(title: season.displayName, removable: true, fill: Theme.paper, isSelected: true) {
                                filter.seasons.remove(season)
                            }
                            .accessibilityLabel(String(localized: "Remove filter: \(season.displayName)"))
                        }
                        ForEach(ClothingItem.Level.allCases.filter { filter.levels[$0] != nil }, id: \.self) { level in
                            let band = filter.levels[level]!
                            FilterChip(title: "\(level.displayName) \(band.rangeText)", removable: true, fill: Theme.paper, isSelected: true) {
                                filter.levels[level] = nil
                            }
                            .accessibilityLabel(String(localized: "Remove filter: \(level.displayName) \(band.displayName)"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 3)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct FilterChip: View {
    let title: String
    var swatch: Color? = nil
    var removable = false
    let fill: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let swatch {
                    Circle()
                        .fill(swatch)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().strokeBorder(Theme.ink.opacity(0.35)))
                }
                Text(title)
                    .font(.ticket(13.5, relativeTo: .subheadline))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                if removable {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .accessibilityHidden(true)
                }
            }
            .padding(.leading, 18)
            .padding(.trailing, 11)
            .padding(.vertical, 5)
            .frame(minHeight: 32)
            .background(TagShape().fill(fill))
            .overlay(TagShape().stroke(Theme.ink, lineWidth: isSelected ? 2 : 0))
            .shadow(color: .black.opacity(0.10), radius: 1, y: 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
