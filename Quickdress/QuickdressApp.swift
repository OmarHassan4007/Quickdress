import SwiftUI
import QuickdressCore
import StoragePlugins

@main
struct QuickdressApp: App {
    @State private var wardrobe: WardrobeViewModel

    init() {
        let bus = EventBus()
        do {
            let items = try SwiftDataItemStore(container: SwiftDataItemStore.makeContainer())
            let photos = try FilePhotoStore()
            let manager = WardrobeManager(items: items, photos: photos, bus: bus)
            #if DEBUG
            SampleWardrobe.addIfEmpty(to: manager)
            #endif
            _wardrobe = State(initialValue: WardrobeViewModel(manager: manager, bus: bus))
        } catch {
            fatalError("Quickdress could not open its storage: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            WardrobeView(model: wardrobe)
        }
    }
}
