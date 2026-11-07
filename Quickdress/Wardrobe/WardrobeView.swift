import SwiftUI
import QuickdressCore

struct WardrobeView: View {
    @Bindable var model: WardrobeViewModel
    @Bindable var addItem: AddItemFlow

    private let columns = [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Wardrobe")
                    .font(.statement(44, relativeTo: .largeTitle))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .accessibilityAddTraits(.isHeader)
                if !model.items.isEmpty && !model.loadFailed {
                    WardrobeFilterBar(filter: $model.filter, colours: model.coloursInWardrobe)
                }
                content
            }
                .background(Theme.ground)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if !model.items.isEmpty {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                addItem.start()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                            }
                            .accessibilityLabel("Check in a piece")
                        }
                    }
                }
                .toolbarBackground(Theme.ground, for: .navigationBar)
                .navigationDestination(for: ClothingItem.self) { item in
                    ItemDetailView(item: item, wardrobe: model)
                }
        }
        .task {
            model.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.loadFailed {
            TicketMessage(
                title: "Wardrobe unavailable",
                text: "Your clothes could not be loaded. Try again later."
            )
        } else if model.items.isEmpty {
            EmptyWardrobe { addItem.start() }
        } else if model.visibleItems.isEmpty {
            TicketMessage(
                title: "No matching pieces",
                text: "Nothing in your wardrobe matches the selected category and colour."
            ) {
                Button("Clear filters") { model.clearFilters() }
                    .buttonStyle(UnderlinedButtonStyle())
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 22) {
                    ForEach(model.visibleItems) { item in
                        NavigationLink(value: item) {
                            ItemCell(item: item) {
                                model.photo(for: item)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
}

/// The first screen of the Wardrobe tab: what to do instead of a blank grid (NFR-04).
struct EmptyWardrobe: View {
    let start: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)
            ZStack(alignment: .top) {
                Capsule().fill(Theme.ink).frame(height: 5).padding(.horizontal, 54)
                HStack(spacing: 36) {
                    ForEach(0..<3, id: \.self) { _ in
                        Image(systemName: "hanger")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(Color(hex: 0x9C978D))
                    }
                }
                .padding(.top, 2)
            }
            .accessibilityHidden(true)
            Text("Nothing checked in yet")
                .font(.statement(31))
                .foregroundStyle(Theme.ink)
                .padding(.top, 40)
            Text("Photograph a top, a bottom and a pair of shoes, and Quickdress can dress you tomorrow morning.")
                .font(.body)
                .foregroundStyle(Theme.secondaryInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            Spacer(minLength: 20)
            Button("Check in your first piece", action: start)
                .buttonStyle(StubButtonStyle(showsArrow: false))
                .padding(.horizontal, 8)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A short message in the ticket look, with an optional action.
struct TicketMessage<Actions: View>: View {
    let title: LocalizedStringKey
    let text: LocalizedStringKey
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.statement(30))
                .foregroundStyle(Theme.ink)
            Text(text)
                .font(.body)
                .foregroundStyle(Theme.secondaryInk)
                .multilineTextAlignment(.center)
            actions
        }
        .padding(.horizontal, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension TicketMessage where Actions == EmptyView {
    init(title: LocalizedStringKey, text: LocalizedStringKey) {
        self.init(title: title, text: text) { EmptyView() }
    }
}
