// AppUITests.swift

import XCTest

final class AppUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Catches a broken container or an unreadable Core Data model, both of which
    /// trap at launch.
    @MainActor
    func testLaunchesToTheProductsTab() throws {
        let app = XCUIApplication()
        // Fixtures; see `AppContainer.stubbed()`.
        app.launchArguments = ["-UITestStubNetwork"]
        app.launch()

        // Only launch is slow on a cold simulator; nothing after it touches the network.
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
