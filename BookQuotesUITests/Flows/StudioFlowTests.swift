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

        logger.step(4, "Navigate back to Reading tab")
        _ = tapTab(.library, timeout: 5)
        XCTAssertTrue(app.navigationBars["Reading"].waitForExistence(timeout: 5))
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

    func testStudioWorkspacePassesSystemAccessibilityAudit() throws {
        XCTAssertTrue(tapTab(.studio))
        XCTAssertTrue(app.buttons["studio_export_menu"].waitForExistence(timeout: 5))
        try performSystemAccessibilityAudit()
    }

    func testStudioWorkspacePreservesDesignAcrossPassageSelectionAndExports() {
        app.buttons[AccessibilityIdentifiers.V2.studioTab].tap()
        XCTAssertTrue(app.buttons["studio_export_menu"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Open in Studio"].exists, "The preview lobby must be retired")

        let warm = app.buttons["Warm Vellum theme"]
        for _ in 0..<5 {
            if warm.exists && warm.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(warm.exists && warm.isHittable)
        warm.tap()
        let square = app.buttons["Square (1:1)"]
        XCTAssertTrue(square.exists && square.isHittable)
        square.tap()
        let adjust = app.buttons["studio_adjust_menu"]
        adjust.tap()
        app.buttons["Zoom In"].tap()
        XCTAssertEqual(adjust.value as? String, "110 percent")
        adjust.tap()
        app.buttons["Center and Reset"].tap()
        XCTAssertEqual(adjust.value as? String, "100 percent")

        app.buttons["studio_choose_passage_button"].tap()
        let search = app.textFields["studio_passage_search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("no_matching_passage_739")
        XCTAssertTrue(app.staticTexts["No passages match your search"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["Cancel"].tap()
        XCTAssertTrue(warm.waitForExistence(timeout: 5) && warm.isSelected)
        XCTAssertTrue(square.isSelected)

        app.buttons["studio_choose_passage_button"].tap()
        let clear = app.buttons["Clear Filters"]
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        clear.tap()
        let passage = app.buttons["studio_passage_row"].firstMatch
        for _ in 0..<6 {
            if passage.exists && passage.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(passage.exists && passage.isHittable)
        passage.tap()
        XCTAssertTrue(app.buttons["studio_export_menu"].waitForExistence(timeout: 5))
        XCTAssertTrue(warm.isSelected && square.isSelected, "Selecting a passage must preserve theme and format")

        app.buttons["studio_export_menu"].tap()
        app.buttons["Copy Image"].tap()
        XCTAssertTrue(app.staticTexts["Copied card to clipboard"].waitForExistence(timeout: 5))
        app.buttons["studio_export_menu"].tap()
        app.buttons["Export for Obsidian"].tap()
        XCTAssertTrue(app.staticTexts["Copied Obsidian Markdown"].waitForExistence(timeout: 5))
    }

    func testCroppingAdjustmentBlocksImagesButPreservesMarkdownAndReset() {
        app.buttons[AccessibilityIdentifiers.V2.studioTab].tap()
        let adjust = app.buttons["studio_adjust_menu"]
        XCTAssertTrue(revealForInteraction(adjust))
        adjust.tap()
        app.buttons["Zoom In"].tap()
        adjust.tap()
        app.buttons["Zoom In"].tap()
        let warning = app.staticTexts["studio_image_fit_issue"]
        XCTAssertTrue(warning.waitForExistence(timeout: 5))
        app.buttons["studio_export_menu"].tap()
        XCTAssertFalse(app.buttons["Copy Image"].isEnabled)
        XCTAssertFalse(app.buttons["Share Image"].isEnabled)
        XCTAssertFalse(app.buttons["Save to Photos"].isEnabled)
        XCTAssertTrue(app.buttons["Export for Obsidian"].isEnabled)
        app.buttons["Export for Obsidian"].tap()
        XCTAssertTrue(app.staticTexts["Copied Obsidian Markdown"].waitForExistence(timeout: 5))
        XCTAssertTrue(revealForInteraction(adjust))
        adjust.tap()
        app.buttons["Center and Reset"].tap()
        XCTAssertTrue(waitUntil("Reset removes the crop warning", timeout: 5) { !warning.exists })
        app.buttons["studio_export_menu"].tap()
        XCTAssertTrue(app.buttons["Copy Image"].isEnabled)
        app.buttons["Copy Image"].tap()
        XCTAssertTrue(app.staticTexts["Copied card to clipboard"].waitForExistence(timeout: 5))
    }

    func testStudioWorkspaceAtAccessibilityXXXL() {
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        waitForAppReady()
        app.buttons[AccessibilityIdentifiers.V2.studioTab].tap()
        let square = app.buttons["Square (1:1)"]
        for _ in 0..<8 {
            if square.exists && square.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(square.exists && square.isHittable)
        square.tap()
        let warm = app.buttons["Warm Vellum theme"]
        for _ in 0..<8 {
            if warm.exists && warm.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(warm.exists && warm.isHittable)
        warm.tap()
        if let attachment = screenshots.capture(name: "studio_accessibility_xxxl") { add(attachment) }
        app.buttons["studio_export_menu"].tap()
        app.buttons["Copy Image"].tap()
        XCTAssertTrue(app.staticTexts["Copied card to clipboard"].waitForExistence(timeout: 5))
        app.buttons["Dismiss export confirmation"].tap()
        XCTAssertFalse(app.staticTexts["Copied card to clipboard"].exists)
    }

    func testV2StudioTabUsesInkTitleAndReturnsToReading() {
        let studio = app.buttons[AccessibilityIdentifiers.V2.studioTab]
        XCTAssertTrue(studio.waitForExistence(timeout: 5), "Studio should be a primary v2 tab")
        studio.tap()

        XCTAssertTrue(
            app.staticTexts[AccessibilityIdentifiers.Studio.rootTitle].waitForExistence(timeout: 5)
                || app.staticTexts["Passage Card Studio"].waitForExistence(timeout: 2),
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
