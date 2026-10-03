// FixedDateProvider.swift

import Foundation

@testable import Products

/// A clock stopped at a fixed instant.
struct FixedDateProvider: DateProvider {
    let now: Date

    init(_ now: Date) {
        self.now = now
    }
}
