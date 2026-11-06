import Foundation

public protocol Plugin {
    var id: String { get }
    var priority: Int { get }
}

extension Plugin {
    public var priority: Int { 0 }
}
