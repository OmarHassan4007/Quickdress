import SwiftUI
import QuickdressCore

struct WardrobeFilterBar: View {
    @Binding var filter: WardrobeFilter
    let colours: [Palette]

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: String(localized: "All"), isSelected: filter.category == nil) {
                        filter.category = nil
                    }
                    ForEach(Category.allCases, id: \.self) { category in
                        FilterChip(title: category.pluralName, isSelected: filter.category == category) {
                            filter.category = filter.category == category ? nil : category
                        }
                    }
                }
                .padding(.horizontal)
            }
            if !colours.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: String(localized: "Any colour"), isSelected: filter.colour == nil) {
                            filter.colour = nil
                        }
                        ForEach(colours, id: \.self) { colour in
                            FilterChip(
                                title: colour.displayName,
                                swatch: colour.swatch,
                                isSelected: filter.colour == colour
                            ) {
                                filter.colour = filter.colour == colour ? nil : colour
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct FilterChip: View {
    let title: String
    let swatch: Color?
    let isSelected: Bool
    let action: () -> Void

    init(title: String, swatch: Color? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.swatch = swatch
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let swatch {
                    Circle()
                        .fill(swatch)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().strokeBorder(Color.secondary.opacity(0.5)))
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemFill), in: Capsule())
            .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
