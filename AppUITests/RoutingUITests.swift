// RoutingUITests.swift

import XCTest

/// End-to-end navigation: unit tests prove the stacks change, not that a push
/// renders.
final class RoutingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Tapping a product opens its detail, tapping the seller pushes the profile on
    /// top, and Back returns to the product.
    @MainActor
    func testTappingASellerPushesTheProfile() throws {
        // The runner inherits the simulator's last orientation; landscape
        // moves the rows out from under the taps below.
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        // Fixtures, so the text below is known exactly and no wait depends on the network.
        app.launchArguments = ["-UITestStubNetwork"]
        app.launch()

        // By id rather than first row: the list sorts by title, and the assertions
        // below follow from product 1.
        let product = app.descendants(matching: .any)["product-row-1"].firstMatch
        XCTAssertTrue(
            product.waitForExistence(timeout: 10),
            "The product list never loaded."
        )
        product.tap()

        // `seller-row` renders only in the loaded state, so waiting for it
        // covers both the push and the load.
        let seller = app.descendants(matching: .any)["seller-row"].firstMatch
        XCTAssertTrue(
            seller.waitForExistence(timeout: 5),
            "Tapping a product did not push a loaded detail screen."
        )
        XCTAssertTrue(
            app.staticTexts["Stub Widget"].firstMatch.exists,
            "The detail screen did not show the product that was tapped."
        )

        seller.tap()

        // Product 1's seller is user 2 in the fixtures.
        XCTAssertTrue(
            app.staticTexts["Stella Seller"].firstMatch.waitForExistence(timeout: 5),
            "Tapping the seller did not open that seller's profile."
        )
        XCTAssertTrue(app.staticTexts["Email"].exists, "The profile did not show its fields.")

        // Pushed onto the Products stack rather than crossing tabs, so there is a Back
        // button and it leads to the product.
        let back = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(back.exists, "The pushed profile had no Back button.")
        back.tap()

        XCTAssertTrue(
            seller.waitForExistence(timeout: 5),
            "Going back from the profile did not return to the product."
        )
    }
}
