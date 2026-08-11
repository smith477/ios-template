//
//  RoutingUITests.swift
//  AppUITests
//

import XCTest

/// End-to-end coverage of navigation, which the unit tests cannot reach: they
/// assert that `AppRouter` mutates its stacks, not that SwiftUI accepts those
/// stacks as bindings or that a push renders.
///
/// Limited to the cross-feature flow — list, detail, then a seller's profile
/// pushed on top — as the path most likely to break without a unit test
/// noticing. It is the one flow where a stack renders another feature's route,
/// so it is what would break if a destination went unregistered.
final class RoutingUITests: XCTestCase {
    /// Whether `testTappingASellerPushesTheProfile` can pass. See its
    /// documentation.
    private static let sellerRowIsTappableUnderTest = false

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Verifies that tapping a product opens its detail screen, that tapping
    /// the seller there pushes that user's profile on top of it, and that Back
    /// returns to the product rather than leaving the Products tab.
    ///
    /// - Warning: Skipped — this test does not currently pass, and a green
    ///   suite does not cover this flow. Tapping the seller row has no effect
    ///   under `XCUITest`, though the flow works when the app is driven by
    ///   hand. Orientation, the element query, accessibility grouping,
    ///   coordinate taps, and the load guard in `didTapSeller` have all been
    ///   excluded. The same button pattern in `ProductView` works, leaving the
    ///   `Section` wrapper in `ProductDetailView` as the remaining difference
    ///   to investigate.
    @MainActor
    func testTappingASellerPushesTheProfile() throws {
        try XCTSkipUnless(Self.sellerRowIsTappableUnderTest)

        // The runner inherits the simulator's last orientation; landscape
        // moves the rows out from under the taps below.
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launch()

        // First run loads the catalogue from the network.
        let firstProduct = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'product-row-'")
        ).firstMatch
        XCTAssertTrue(
            firstProduct.waitForExistence(timeout: 30),
            "The product list never loaded."
        )
        firstProduct.tap()

        let seller = app.descendants(matching: .any)["seller-row"].firstMatch
        XCTAssertTrue(
            seller.waitForExistence(timeout: 15),
            "Tapping a product did not push the detail screen."
        )
        // The seller tap is ignored until the product loads, and the price
        // renders only in the loaded state.
        let price = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'US$'")
        ).firstMatch
        XCTAssertTrue(
            price.waitForExistence(timeout: 30),
            "The detail screen never finished loading."
        )

        seller.tap()

        // Which user appears depends on live data, so the profile is
        // identified by its fields rather than by name.
        XCTAssertTrue(
            app.staticTexts["Email"].waitForExistence(timeout: 30),
            "Tapping the seller did not open a user profile."
        )
        XCTAssertTrue(app.staticTexts["Name"].exists)

        // The point of pushing rather than crossing tabs: the profile sits on
        // the Products stack, so there is a Back button and it leads to the
        // product. A profile that had replaced the Users tab's stack would be
        // a root, with nothing to go back to.
        let back = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(back.exists, "The pushed profile had no Back button.")
        back.tap()

        XCTAssertTrue(
            seller.waitForExistence(timeout: 15),
            "Going back from the profile did not return to the product."
        )
    }
}
