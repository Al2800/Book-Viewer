import XCTest

final class StudioFlowTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-search-test-data",
            "--app-store-media",
            "--disable-animations"
        ]
    }

    func testStudioTabNavigationAndThemeSelection() {
        logger.step(1, "Navigate to Studio tab")
        _ = tapTab(.studio, timeout: 5)

        logger.step(2, "Verify Studio header or navigation bar exists")
        let studioNav = app.navigationBars["Studio"]
        XCTAssertTrue(
            studioNav.waitForExistence(timeout: 5) || app.staticTexts[AccessibilityIdentifiers.Studio.rootTitle].waitForExistence(timeout: 2),
            "Studio navigation bar or title should exist"
        )

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

final class V2StudioFlowTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-search-test-data",
            "--product-experience-v2",
            "--disable-animations"
        ]
    }

    func testV2StudioTabUsesInkTitleAndReturnsToReading() {
        let studio = app.buttons[AccessibilityIdentifiers.V2.studioTab]
        XCTAssertTrue(studio.waitForExistence(timeout: 5), "Studio should be a primary v2 tab")
        studio.tap()

        XCTAssertTrue(
            app.staticTexts[AccessibilityIdentifiers.Studio.rootTitle].waitForExistence(timeout: 5)
                || app.staticTexts["Quote Card Studio"].waitForExistence(timeout: 2),
            "Studio tab should show the Studio title"
        )

        let darkLinenButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Dark Linen'")).firstMatch
        if darkLinenButton.waitForExistence(timeout: 3) {
            darkLinenButton.tap()
        }

        let reading = app.buttons[AccessibilityIdentifiers.V2.readingTab]
        XCTAssertTrue(reading.waitForExistence(timeout: 5), "Reading should remain a primary v2 tab")
        reading.tap()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.V2.settingsButton].waitForExistence(timeout: 5))
    }
}
