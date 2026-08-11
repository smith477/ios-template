// DateProvider.swift

import Foundation

/// Supplies the current date, so tests can decide what "now" means rather
/// than racing the wall clock.
public protocol DateProvider: Sendable {
    var now: Date { get }
}

/// The production conformance.
public struct SystemDateProvider: DateProvider {
    public init() {}

    public var now: Date { Date() }
}

/// A clock stopped at a fixed instant, shipped so tests need not redefine it.
public struct FixedDateProvider: DateProvider {
    public let now: Date

    public init(_ now: Date) {
        self.now = now
    }
}
