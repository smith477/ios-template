// DateProvider.swift

import Foundation

/// A source of the current date that tests can control.
protocol DateProvider: Sendable {
    var now: Date { get }
}

/// The system clock.
struct SystemDateProvider: DateProvider {
    init() {}

    var now: Date { Date() }
}

/// A clock stopped at a fixed instant, for tests.
struct FixedDateProvider: DateProvider {
    let now: Date

    init(_ now: Date) {
        self.now = now
    }
}
