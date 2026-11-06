import Foundation

public enum AppEvent: Equatable, Sendable {
    case itemSaved(id: UUID)
    case itemDeleted(id: UUID)
}
