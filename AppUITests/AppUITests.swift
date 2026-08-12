// AppUITests.swift

import XCTest

final class AppUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The app launches and reaches its first screen rather than a blank
    /// window — the check that catches a broken container or a Core Data model
    /// the app cannot open, both of which trap at startup.
    @MainActor
    func testLaunchesToTheProductsTab() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.tabBars.buttons["Products"].waitForExistence(timeout: 30),
            "The app did not reach its tab bar."
        )
        XCTAssertTrue(app.tabBars.buttons["Users"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
