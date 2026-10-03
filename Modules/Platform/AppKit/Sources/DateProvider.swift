// DateProvider.swift

import Foundation

/// A source of the current date that tests can control.
public protocol DateProvider: Sendable {
    var now: Date { get }
}

/// The system clock.
public struct SystemDateProvider: DateProvider {
    public init() {}

    public var now: Date { Date() }
}

/// A clock stopped at a fixed instant, for tests.
public struct FixedDateProvider: DateProvider {
    public let now: Date

    public init(_ now: Date) {
        self.now = now
    }
}
