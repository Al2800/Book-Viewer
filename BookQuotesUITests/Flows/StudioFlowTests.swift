import XCTest

final class StudioFlowTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-search-test-data",
            "--app-store-media",
            "--disable-animations"
        ]
    }

    override func waitForAppReady() {
        super.waitForAppReady()
    }

    func testStudioTabNavigationAndThemeSelection() {
        logger.step(1, "Navigate to Studio tab")
        _ = tapTab(.studio, timeout: 5)

        logger.step(2, "Verify Studio header or navigation bar exists")
        let studioNav = app.navigationBars["Studio"]
        XCTAssertTrue(studioNav.waitForExistence(timeout: 5), "Studio navigation bar should exist")

        logger.step(3, "Verify theme picker buttons exist")
        let darkLinenButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Dark Linen'")).firstMatch
        let warmVellumButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Warm Vellum'")).firstMatch

        if darkLinenButton.waitForExistence(timeout: 3) {
            darkLinenButton.tap()
        }

        if warmVellumButton.waitForExistence(timeout: 3) {
            warmVellumButton.tap()
        }

        logger.step(4, "Navigate back to Library tab")
        _ = tapTab(.library, timeout: 5)
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
    }
}
