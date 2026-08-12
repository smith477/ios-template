// DateProviderTests.swift

import Foundation
import Testing

@testable import AppKit

struct DateProviderTests {
    /// The point of the protocol: a test decides what "now" is.
    @Test
    func fixedProviderReturnsTheDateItWasGiven() {
        let instant = Date(timeIntervalSince1970: 1_000_000)

        let provider = FixedDateProvider(instant)

        #expect(provider.now == instant)
        #expect(provider.now == instant, "a second read returns the same instant")
    }

    /// The system provider tracks the wall clock rather than caching its first
    /// reading.
    @Test
    func systemProviderAdvances() async throws {
        let provider = SystemDateProvider()

        let first = provider.now
        try await Task.sleep(for: .milliseconds(20))
        let second = provider.now

        #expect(second > first)
    }
}
