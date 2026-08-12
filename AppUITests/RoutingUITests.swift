// RoutingUITests.swift

import XCTest

/// End-to-end coverage of navigation, which the unit tests cannot reach: they
/// assert that `AppRouter` mutates its stacks, not that a push renders.
final class RoutingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Tapping a product opens its detail, tapping the seller pushes that
    /// user's profile on top of it, and Back returns to the product rather
    /// than leaving the Products tab.
    ///
    /// Two defects sat behind the skip this test used to carry, and both are
    /// fixed. The first: both rows applied `.contentShape(.rect)` to the
    /// `Button` rather than its label, so a `.plain` button hit-tested only its
    /// opaque subviews and most of each row ignored taps.
    ///
    /// The second was described as the app freezing once a screen is pushed.
    /// It was really a missing observation: a pushed screen held its
    /// `@Observable` view model in a plain `let`, so SwiftUI never registered a
    /// dependency on it and the view was never invalidated when `state` left
    /// `.loading`. The push and the `.task` both ran — the screen just kept
    /// drawing its `ProgressView` forever. The root views escaped it only
    /// because `TemplateApp` keeps their view models in `@State`.
    @MainActor
    func testTappingASellerPushesTheProfile() throws {
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

        // `seller-row` renders only in the loaded state, so waiting for it
        // covers both the push and the load. Asserting on the price as well
        // added nothing but a second dependency on how fast the live API
        // answers, which is what made this fail on CI.
        let seller = app.descendants(matching: .any)["seller-row"].firstMatch
        XCTAssertTrue(
            seller.waitForExistence(timeout: 30),
            "Tapping a product did not push a loaded detail screen."
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
