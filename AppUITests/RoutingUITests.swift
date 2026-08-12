// RoutingUITests.swift

import XCTest

/// End-to-end coverage of navigation, which the unit tests cannot reach: they
/// assert that `AppRouter` mutates its stacks, not that a push renders.
final class RoutingUITests: XCTestCase {
    /// Whether the app can get past its first screen. See
    /// `testTappingASellerPushesTheProfile`.
    private static let appLoadsPastTheProductList = false

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Tapping a product opens its detail, tapping the seller pushes that
    /// user's profile on top of it, and Back returns to the product rather
    /// than leaving the Products tab.
    ///
    /// - Warning: Skipped, and a green suite does not cover this flow. Two
    ///   separate defects sat behind the original skip. The first is fixed:
    ///   both rows applied `.contentShape(.rect)` to the `Button` instead of
    ///   its label, so a `.plain` button hit-tested only its opaque subviews
    ///   and most of each row ignored taps. The second is open: once a screen
    ///   is pushed, the app freezes — the pushed view sits on a spinner, the
    ///   tab bar and Back stop responding, and `sample` shows every thread
    ///   parked with no app code running. It reproduces by hand and on a
    ///   baseline build with none of these changes, so it predates them.
    @MainActor
    func testTappingASellerPushesTheProfile() throws {
        try XCTSkipUnless(Self.appLoadsPastTheProductList)

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
