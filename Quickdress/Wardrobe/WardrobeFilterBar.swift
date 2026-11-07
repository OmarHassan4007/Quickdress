import SwiftUI
import QuickdressCore

/// Category and colour filters, drawn as paper tags (FR-04).
struct WardrobeFilterBar: View {
    @Binding var filter: WardrobeFilter
    let colours: [Palette]

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
        }
        .padding(.vertical, 6)
    }
}

struct FilterChip: View {
    let title: String
    var swatch: Color? = nil
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
            }
            .padding(.leading, 18)
            .padding(.trailing, 11)
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
