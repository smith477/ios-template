// MovableDateProvider.swift

import Foundation
import Synchronization

@testable import Products

/// A clock that can be moved forward mid-test.
final class MovableDateProvider: DateProvider {
    private let current: Mutex<Date>

    init(_ start: Date) {
        current = Mutex(start)
    }

    var now: Date { current.withLock { $0 } }

    func advance(by interval: TimeInterval) {
        current.withLock { $0 += interval }
    }
}
