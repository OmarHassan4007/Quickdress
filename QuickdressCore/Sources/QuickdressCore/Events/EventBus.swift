import Foundation

@MainActor
public final class EventBus {
    private var subscribers: [@MainActor (AppEvent) -> Void] = []

    public init() {}

    public func subscribe(_ handler: @escaping @MainActor (AppEvent) -> Void) {
        subscribers.append(handler)
    }

    public func publish(_ event: AppEvent) {
        for handler in subscribers {
            handler(event)
        }
    }
}
