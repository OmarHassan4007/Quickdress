import Foundation

public enum Season: String, CaseIterable, Codable, Sendable {
    case spring
    case summer
    case autumn
    case winter

    public init(month: Int) {
        switch month {
        case 12, 1, 2: self = .winter
        case 3...5: self = .spring
        case 6...8: self = .summer
        case 9...11: self = .autumn
        default: preconditionFailure("month must be 1...12, got \(month)")
        }
    }

    public static func current(on date: Date = .now, calendar: Calendar = .current) -> Season {
        Season(month: calendar.component(.month, from: date))
    }
}
