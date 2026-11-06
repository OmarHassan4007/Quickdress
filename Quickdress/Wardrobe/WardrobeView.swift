import SwiftUI
import QuickdressCore

struct WardrobeView: View {
    @Bindable var model: WardrobeViewModel

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 8)]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Wardrobe")
                .safeAreaInset(edge: .top, spacing: 0) {
                    if !model.items.isEmpty && !model.loadFailed {
                        WardrobeFilterBar(filter: $model.filter, colours: model.coloursInWardrobe)
                            .background(.bar)
                    }
                }
                .navigationDestination(for: ClothingItem.self) { item in
                    ItemDetailView(item: item, photo: model.photo(for: item))
                }
        }
        .task {
            model.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.loadFailed {
            ContentUnavailableView(
                "Wardrobe unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text("Your clothes could not be loaded. Try again later.")
            )
        } else if model.items.isEmpty {
            ContentUnavailableView(
                "No clothes yet",
                systemImage: "tshirt",
                description: Text("Add your first item and it will appear here.")
            )
        } else if model.visibleItems.isEmpty {
            ContentUnavailableView {
                Label("No matching items", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("No items match the selected category and colour.")
            } actions: {
                Button("Clear filters") {
                    model.clearFilters()
                }
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(model.visibleItems) { item in
                        NavigationLink(value: item) {
                            ItemCell(item: item) {
                                model.photo(for: item)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }
}
