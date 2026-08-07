// DateProvider.swift

import Foundation

/// Supplies the current date.
///
/// Types that read the clock take one of these rather than calling `Date()`,
/// so a test can decide what "now" means instead of racing the wall clock.
public protocol DateProvider: Sendable {
    var now: Date { get }
}

/// The system clock. The production conformance.
public struct SystemDateProvider: DateProvider {
    public init() {}

    public var now: Date { Date() }
}

/// A clock stopped at a fixed instant.
///
/// Ships alongside the real one so every feature's tests get it without
/// redefining it — the same reason `StorageProvider.inMemory` is public.
public struct FixedDateProvider: DateProvider {
    public let now: Date

    public init(_ now: Date) {
        self.now = now
    }
}
