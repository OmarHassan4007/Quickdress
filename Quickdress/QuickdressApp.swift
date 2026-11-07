import SwiftUI
import QuickdressCore
import StoragePlugins
import CapturePlugins

@main
struct QuickdressApp: App {
    @State private var wardrobe: WardrobeViewModel
    @State private var addItem: AddItemFlow

    init() {
        Theme.registerFonts()
        let bus = EventBus()
        do {
            let items = try SwiftDataItemStore(container: SwiftDataItemStore.makeContainer())
            let photos = try FilePhotoStore()
            let manager = WardrobeManager(items: items, photos: photos, bus: bus)
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-sampleWardrobe") {
                SampleWardrobe.addIfEmpty(to: manager)
            }
            #endif
            try? manager.numberUnnumberedItems()
            _wardrobe = State(initialValue: WardrobeViewModel(manager: manager, bus: bus))
            _addItem = State(initialValue: AddItemFlow(
                sources: [CameraSource(), PhotoLibrarySource()],
                manager: manager
            ))
        } catch {
            fatalError("Quickdress could not open its storage: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            WardrobeView(model: wardrobe, addItem: addItem)
                .sheet(isPresented: $addItem.isSheetPresented, onDismiss: addItem.sheetDidDismiss) {
                    AddItemSheet(flow: addItem)
                }
                .fullScreenCover(item: $addItem.checkIn) { checkIn in
                    CheckInView(
                        model: checkIn,
                        onRetake: addItem.retake,
                        onFinish: addItem.finish
                    )
                }
                .alert("This photo can't be used", isPresented: Binding(
                    get: { addItem.errorMessage != nil },
                    set: { if !$0 { addItem.errorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Try another photo.")
                }
                .tint(Theme.ink)
                // The ticket look is designed for light mode only so far; dark variants come in Sprint 2.
                .preferredColorScheme(.light)
        }
    }
}
