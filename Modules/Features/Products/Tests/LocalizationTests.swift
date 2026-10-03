// LocalizationTests.swift

import Foundation
import Testing

@testable import Products

struct LocalizationTests {
    /// SwiftUI looks a feature's text up in the app's bundle, so the catalog has to
    /// reach the bundle `String(localized:bundle:)` is given.
    @Test
    func theFeaturesStringsShipInItsOwnBundle() {
        let strings = Products.modelBundle.url(
            forResource: "Localizable",
            withExtension: "strings",
            subdirectory: nil,
            localization: "en"
        )
        #expect(strings != nil)
    }
}
