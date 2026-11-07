import Foundation
import UIKit
import Observation
import QuickdressCore
import CapturePlugins

/// The check-in receipt for one new or existing item (FR-02).
@MainActor
@Observable
final class CheckInViewModel: Identifiable {
    enum Line: CaseIterable {
        case category, colour, warmth, formality, comfort, season
    }

    let id: UUID
    var isNewItem: Bool
    let originalPhoto: Data
    private(set) var cutOut: Data?
    private(set) var isCuttingOut = false
    private(set) var isReadingDetails = false
    var useOriginal = false

    let number: Int
    var category: QuickdressCore.Category?
    var colour: Palette?
    /// The exact colour, from the colour wheel or measured from the photo.
    var exactColour: RGB?
    /// Lines the app filled in itself; the user is asked to check them.
    private(set) var suggested: Set<Line> = []
    var warmth = 3
    var formality = 3
    var comfort = 3
    var seasons: Set<Season> = []
    /// A line the user tapped to change. Otherwise the first unanswered line is open.
    var openLine: Line?

    private(set) var saved: ClothingItem?
    var saveError: String?

    @ObservationIgnored private let manager: WardrobeManager
    @ObservationIgnored private let lifter = SubjectLifter()
    @ObservationIgnored private let analyzer = ItemAnalyzer()

    // MARK: Initializers

    /// Init for creating a NEW item
    init(photo: Data, manager: WardrobeManager) {
        self.id = UUID()
        self.originalPhoto = photo
        self.manager = manager
        self.number = (try? manager.nextNumber()) ?? 1
        self.isNewItem = true
    }

    /// Init for editing an EXISTING item
    init(item: ClothingItem, manager: WardrobeManager) {
        self.id = item.id
        self.originalPhoto = item.photo
        self.manager = manager
        self.useOriginal = true
        self.category = item.category
        self.colour = item.colour
        if let exactHex = item.exactColour {
            self.exactColour = RGB(hex: exactHex)
        }
        self.warmth = item.warmth
        self.formality = item.formality
        self.comfort = item.comfort
        self.seasons = item.seasons
        self.isNewItem = false
        self.number = item.number
    }

    func start() {
        // Skip cutout/AI auto-tagging when editing an existing item
        guard isNewItem else { return }

        isCuttingOut = true
        Task {
            let lifted = await lifter.lift(originalPhoto)
            cutOut = lifted
            isCuttingOut = false
            isReadingDetails = true
            let suggestion = await analyzer.suggest(for: lifted ?? originalPhoto)
            apply(suggestion)
            isReadingDetails = false
        }
    }

    /// Fills in every line the user has not answered yet (FR-13). The user can change any of them.
    func apply(_ suggestion: ItemSuggestion) {
        if category == nil, let value = suggestion.category { category = value; suggested.insert(.category) }
        if colour == nil, let value = suggestion.colour {
            colour = value
            exactColour = suggestion.exactColour
            suggested.insert(.colour)
        }
        if let value = suggestion.warmth { warmth = value; suggested.insert(.warmth) }
        if let value = suggestion.formality { formality = value; suggested.insert(.formality) }
        if let value = suggestion.comfort { comfort = value; suggested.insert(.comfort) }
        if seasons.isEmpty, !suggestion.seasons.isEmpty { seasons = suggestion.seasons; suggested.insert(.season) }
    }

    // MARK: Photo

    var photoToSave: Data {
        if useOriginal { return originalPhoto }
        return cutOut ?? originalPhoto
    }

    var showsCutOut: Bool { !useOriginal && cutOut != nil }

    var displayImage: UIImage? { UIImage(data: isCuttingOut ? originalPhoto : photoToSave) }

    // MARK: Receipt

    var firstUnanswered: Line? {
        if category == nil { return .category }
        if colour == nil { return .colour }
        if seasons.isEmpty { return .season }
        return nil
    }

    /// The line circled in stamp ink, with its choices open under it.
    var activeLine: Line? {
        guard !isPreparing, saved == nil else { return nil }
        return openLine ?? firstUnanswered
    }

    var isComplete: Bool { firstUnanswered == nil }

    var stubTitle: String {
        if isCuttingOut { return String(localized: "Cutting it out…") }
        if isReadingDetails { return String(localized: "Reading the details…") }
        switch firstUnanswered {
        case .category: return String(localized: "Pick a category first")
        case .colour: return String(localized: "Pick a colour first")
        case .season: return String(localized: "Pick a season first")
        default: return String(localized: "Check it in")
        }
    }

    var isPreparing: Bool { isCuttingOut || isReadingDetails }

    var canSave: Bool { isComplete && !isPreparing && saved == nil }

    var tagText: String { ClothingItem.tagText(saved?.number ?? number) }

    func tap(_ line: Line) {
        guard saved == nil else { return }
        openLine = activeLine == line ? nil : line
    }

    func choose(_ category: QuickdressCore.Category) {
        self.category = category
        suggested.remove(.category)
        openLine = nil
    }

    func choose(_ colour: Palette) {
        self.colour = colour
        exactColour = nil
        suggested.remove(.colour)
        openLine = nil
    }

    /// From the colour wheel or its eyedropper: keep the exact colour and name it by the nearest palette colour.
    func chooseExact(_ colour: RGB) {
        exactColour = colour
        self.colour = Palette.nearest(to: colour)
        suggested.remove(.colour)
    }

    func setLevel(_ line: Line, to value: Int) {
        switch line {
        case .warmth: warmth = value
        case .formality: formality = value
        case .comfort: comfort = value
        default: return
        }
        suggested.remove(line)
        openLine = nil
    }

    func level(_ line: Line) -> Int {
        switch line {
        case .warmth: return warmth
        case .formality: return formality
        case .comfort: return comfort
        default: return 0
        }
    }

    func adjust(_ line: Line, by step: Int) {
        let value = min(5, max(1, level(line) + step))
        switch line {
        case .warmth: warmth = value
        case .formality: formality = value
        case .comfort: comfort = value
        default: return
        }
        suggested.remove(line)
    }

    func toggle(_ season: Season) {
        if seasons.contains(season) {
            seasons.remove(season)
        } else {
            seasons.insert(season)
        }
        suggested.remove(.season)
        openLine = .season
    }

    var seasonsText: String {
        Season.allCases.filter { seasons.contains($0) }.map(\.displayName).joined(separator: ", ")
    }

    // MARK: Saving & Updating

    /// Saves or updates the item through the manager.
    func save() -> Bool {
        guard canSave, let category, let colour else { return false }
        
        let itemToSave = ClothingItem(
            id: id,
            category: category,
            colour: colour,
            warmth: warmth,
            formality: formality,
            comfort: comfort,
            seasons: seasons,
            number: number,
            exactColour: exactColour?.hex
        )
        
        do {
            if isNewItem {
                saved = try manager.addItem(itemToSave, photo: photoToSave)
            } else {
                saved = try manager.updateItem(itemToSave, photo: photoToSave)
            }
            openLine = nil
            return true
        } catch {
            saveError = String(localized: "Nothing was saved. Try again, or cancel and try again.")
            return false
        }
    }

    var hasUnsavedWork: Bool { saved == nil }
}
