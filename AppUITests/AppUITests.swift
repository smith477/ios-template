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
        // Fixtures rather than dummyjson.com; see `AppContainer.stubbed()`.
        app.launchArguments = ["-UITestStubNetwork"]
        app.launch()

        // Launch is the only wait left: a cold simulator can take several
        // seconds to start the app, but nothing after it touches the network.
        XCTAssertTrue(
            app.tabBars.buttons["Products"].waitForExistence(timeout: 10),
            "The app did not reach its tab bar."
        )
        XCTAssertTrue(app.tabBars.buttons["Users"].exists)
        XCTAssertTrue(
            app.staticTexts["Stub Widget"].waitForExistence(timeout: 5),
            "The product list did not show the stub fixtures."
        )
    }
}
