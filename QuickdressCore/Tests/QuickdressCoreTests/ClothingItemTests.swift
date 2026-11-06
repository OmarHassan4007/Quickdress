import XCTest
import QuickdressCore

final class ClothingItemTests: XCTestCase {
    private func makeItem(
        warmth: Int = 3,
        formality: Int = 2,
        comfort: Int = 4,
        seasons: Set<Season> = [.spring, .autumn]
    ) -> ClothingItem {
        ClothingItem(
            category: .top,
            colour: .navy,
            warmth: warmth,
            formality: formality,
            comfort: comfort,
            seasons: seasons
        )
    }

    func testValidItemHasNoErrors() throws {
        let item = makeItem()
        XCTAssertTrue(item.isValid)
        XCTAssertEqual(item.validationErrors, [])
        XCTAssertNoThrow(try item.validate())
    }

    func testLevelBoundsAreInclusive() {
        XCTAssertTrue(makeItem(warmth: 1, formality: 1, comfort: 1).isValid)
        XCTAssertTrue(makeItem(warmth: 5, formality: 5, comfort: 5).isValid)
    }

    func testEachLevelOutsideOneToFiveIsRejected() {
        XCTAssertEqual(makeItem(warmth: 0).validationErrors, [.levelOutOfRange(.warmth, value: 0)])
        XCTAssertEqual(makeItem(formality: 6).validationErrors, [.levelOutOfRange(.formality, value: 6)])
        XCTAssertEqual(makeItem(comfort: -1).validationErrors, [.levelOutOfRange(.comfort, value: -1)])
    }

    func testItemWithNoSeasonIsRejected() {
        XCTAssertEqual(makeItem(seasons: []).validationErrors, [.noSeason])
    }

    func testAllProblemsAreReportedInOrder() {
        let item = makeItem(warmth: 9, comfort: 0, seasons: [])
        XCTAssertEqual(item.validationErrors, [
            .levelOutOfRange(.warmth, value: 9),
            .levelOutOfRange(.comfort, value: 0),
            .noSeason,
        ])
    }

    func testValidateThrowsTheFirstProblem() {
        let item = makeItem(formality: 7, seasons: [])
        XCTAssertThrowsError(try item.validate()) { error in
            XCTAssertEqual(error as? ClothingItem.ValidationError, .levelOutOfRange(.formality, value: 7))
        }
    }

    func testCodableRoundTripKeepsEveryAttribute() throws {
        var item = makeItem()
        item.photo = "3F2A.jpg"
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClothingItem.self, from: data)
        XCTAssertEqual(decoded, item)
    }

    func testRawValuesAreStable() {
        XCTAssertEqual(Category.allCases.map(\.rawValue), ["top", "bottom", "outerwear", "shoes", "accessory"])
        XCTAssertEqual(Season.allCases.map(\.rawValue), ["spring", "summer", "autumn", "winter"])
        XCTAssertEqual(Palette.grey.rawValue, "grey")
    }

    func testPaletteHasTwelveColoursAndFiveNeutrals() {
        XCTAssertEqual(Palette.allCases.count, 12)
        XCTAssertEqual(Palette.allCases.filter(\.isNeutral), [.black, .white, .grey, .navy, .beige])
    }

    func testSeasonFollowsCalendarMonths() {
        let expected: [Int: Season] = [
            1: .winter, 2: .winter, 3: .spring, 4: .spring, 5: .spring, 6: .summer,
            7: .summer, 8: .summer, 9: .autumn, 10: .autumn, 11: .autumn, 12: .winter,
        ]
        for (month, season) in expected {
            XCTAssertEqual(Season(month: month), season, "month \(month)")
        }
    }

    func testCurrentSeasonUsesTheDatesMonth() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Africa/Cairo"))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 6)))
        XCTAssertEqual(Season.current(on: date, calendar: calendar), .autumn)
    }
}
