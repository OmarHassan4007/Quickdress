import XCTest
import QuickdressCore

@MainActor
final class EventBusTests: XCTestCase {
    @MainActor
    private final class OrderLog {
        var entries: [String] = []
    }

    func testHandlersRunInSubscriptionOrder() {
        let bus = EventBus()
        let log = OrderLog()
        bus.subscribe { _ in log.entries.append("first") }
        bus.subscribe { _ in log.entries.append("second") }

        bus.publish(.itemSaved(id: UUID()))

        XCTAssertEqual(log.entries, ["first", "second"])
    }

    func testEveryPublishedEventIsDelivered() {
        let bus = EventBus()
        let log = EventLog(bus: bus)
        let saved = UUID()
        let deleted = UUID()

        bus.publish(.itemSaved(id: saved))
        bus.publish(.itemDeleted(id: deleted))

        XCTAssertEqual(log.events, [.itemSaved(id: saved), .itemDeleted(id: deleted)])
    }

    func testPublishingWithNoSubscribersDoesNothing() {
        let bus = EventBus()
        bus.publish(.itemDeleted(id: UUID()))
    }
}
