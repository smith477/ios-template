// DateProvider.swift

import Foundation

/// A source of the current date that tests can control.
protocol DateProvider: Sendable {
    var now: Date { get }
}

/// The system clock.
struct SystemDateProvider: DateProvider {
    var now: Date { Date() }
}
