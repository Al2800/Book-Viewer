import XCTest

// MARK: - App Store Screenshots

/// Captures the App Store screenshot set using seeded UI test data.
final class AppStoreScreenshotsTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-search-test-data",
            "--mock-camera",
            "--app-store-media",
            "--disable-animations"
        ]
    }

    override func waitForAppReady() {
        super.waitForAppReady()
        navigateToLibraryTabIfNeeded()
    }

    func testAppStoreScreenshots() {
        logger.step(1, "Library grid")
        navigateToLibraryTabIfNeeded()
        switchToGridViewIfPossible()
        captureScreenshot(named: "01_library_grid", description: "Library grid with seeded books")

        logger.step(2, "Library list")
        navigateToLibraryTabIfNeeded()
        switchToListViewIfPossible()
        captureScreenshot(named: "02_library_list", description: "Library list with seeded books")

        logger.step(3, "Book detail")
        switchToGridViewIfPossible()
        openFirstBookDetailForMedia()
        captureScreenshot(named: "03_book_detail", description: "Book detail with quotes")

        logger.step(4, "Quote detail")
        openFirstQuoteDetailForMedia()
        captureScreenshot(named: "04_quote_detail", description: "Quote detail editor")

        logger.step(5, "Search results")
        returnToLibraryRootForMedia()
        showSearchResultsForMedia(query: UITestData.SearchTokens.habits)
        captureScreenshot(named: "05_search_results", description: "Search results for seeded quotes")

        logger.step(6, "Capture")
        returnToLibraryRootForMedia()
        showQuoteCaptureCameraForMedia()
        captureScreenshot(named: "06_capture", description: "Quote capture camera")

        logger.step(7, "Add Book")
        openCoverCaptureForMedia()
        captureScreenshot(named: "07_add_book", description: "Add Book cover capture flow")

        logger.step(8, "Settings")
        showSettingsForMedia()
        captureScreenshot(named: "08_settings", description: "Settings")
    }
}

// MARK: - App Store Previews

/// Drives an App Store preview flow while a simulator recording is running.
final class AppStorePreviewsTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-search-test-data",
            "--mock-camera",
            "--app-store-media",
            "--disable-animations"
        ]
    }

    override func waitForAppReady() {
        super.waitForAppReady()
        navigateToLibraryTabIfNeeded()
    }

    func testPreview_LibraryToQuoteFlow() {
        navigateToLibraryTabIfNeeded()
        switchToGridViewIfPossible()
        waitForLibraryLoadedForMedia()

        openFirstBookDetailForMedia()
        waitForBookDetailLoadedForMedia()

        app.swipeUp()
        pause(previewStepPause)

        openFirstQuoteDetailForMedia()
        waitForQuoteDetailLoadedForMedia()
        pause(previewStepPause)

        tapBackButton()
        waitForBookDetailLoadedForMedia()
        pause(previewStepPause)

        showQuoteCaptureCameraForMedia()
        waitForCaptureLandingLoadedForMedia()
        pause(previewStepPause)
    }
}

// MARK: - Subscription Review Screenshot

/// Captures the onboarding paywall used for subscription review metadata.
final class AppStoreSubscriptionReviewTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--reset-onboarding",
            "--app-store-media",
            "--media-screen",
            "subscription",
            "--disable-animations"
        ]
    }

    override func waitForAppReady() {
        let paywallTitle = app.staticTexts["Choose Your Plan"]
        XCTAssertTrue(
            paywallTitle.waitForExistence(timeout: 8),
            "Subscription media route should open the onboarding paywall"
        )
    }

    func testSubscriptionReviewScreenshot() {
        let paywallTitle = app.staticTexts["Choose Your Plan"]
        assertExists(paywallTitle, timeout: 5, "Subscription screen not shown")

        let yearlyPlan = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Yearly")
        ).firstMatch
        XCTAssertTrue(yearlyPlan.waitForExistence(timeout: 5), "Subscription screen should show the yearly plan")

        let startTrial = app.buttons["Start Free Trial"]
        XCTAssertTrue(startTrial.exists && startTrial.isEnabled, "Subscription screen should offer a start-trial action")

        let freeTrialBadge = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'free trial'")
        ).firstMatch
        XCTAssertTrue(
            freeTrialBadge.waitForExistence(timeout: 5),
            "Expected free trial messaging on subscription screen"
        )

        captureScreenshot(
            named: "subscription_review",
            description: "Subscription review screenshot from onboarding paywall"
        )
    }
}

/// Regression coverage for the onboarding subscription screen at accessibility text sizes.
final class AdaptiveSubscriptionLayoutTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--reset-onboarding",
            "--app-store-media",
            "--media-screen",
            "subscription",
            "--disable-animations",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
    }

    override func waitForAppReady() {
        XCTAssertTrue(
            app.staticTexts["Choose Your Plan"].waitForExistence(timeout: 8),
            "Subscription media route should open the onboarding paywall"
        )
    }

    func testSubscriptionActionsRemainReachableWithAccessibilityText() {
        let yearlyPlan = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Yearly")
        ).firstMatch
        XCTAssertTrue(yearlyPlan.waitForExistence(timeout: 5), "Subscription screen should show the yearly plan")
        XCTAssertTrue(reveal(yearlyPlan), "Yearly plan should remain reachable")

        let startTrial = app.buttons["Start Free Trial"]
        XCTAssertTrue(startTrial.waitForExistence(timeout: 5), "Subscription screen should show Start Free Trial")
        XCTAssertTrue(reveal(startTrial), "Start Free Trial should remain reachable")

        let maybeLater = app.buttons["Maybe later"]
        XCTAssertTrue(maybeLater.waitForExistence(timeout: 5), "Subscription screen should show Maybe later")
        XCTAssertTrue(reveal(maybeLater), "Maybe later should remain reachable")
        captureScreenshot(
            named: "accessibility_text_subscription",
            description: "Subscription screen at accessibility text size"
        )
    }

    private func reveal(_ element: XCUIElement) -> Bool {
        for _ in 0..<10 {
            if element.exists && element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }
}

// MARK: - Shared Helpers

fileprivate extension BaseUITestCase {
    func navigateToLibraryTabIfNeeded() {
        if app.navigationBars["Library"].exists {
            return
        }
        _ = tapTab(.library, timeout: 3)
    }

    func switchToGridViewIfPossible() {
        let viewModeToggle = app.segmentedControls[AccessibilityIdentifiers.Library.viewModeToggle]
        guard viewModeToggle.waitForExistence(timeout: 2) else { return }
        if viewModeToggle.buttons.count > 0 {
            viewModeToggle.buttons.element(boundBy: 0).tap()
        }
    }

    func switchToListViewIfPossible() {
        let viewModeToggle = app.segmentedControls[AccessibilityIdentifiers.Library.viewModeToggle]
        guard viewModeToggle.waitForExistence(timeout: 2) else { return }
        if viewModeToggle.buttons.count > 1 {
            viewModeToggle.buttons.element(boundBy: 1).tap()
        }
    }

    func waitForLibraryLoadedForMedia() {
        // Any stable element that indicates we're on the library root.
        let viewModeToggle = app.segmentedControls[AccessibilityIdentifiers.Library.viewModeToggle]
        assertExists(viewModeToggle, timeout: 6, "Library root not loaded (view mode toggle missing)")
    }

    func waitForBookDetailLoadedForMedia() {
        let title = app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle]
        assertExists(title, timeout: 6, "Book detail not loaded (title missing)")
    }

    func waitForQuoteDetailLoadedForMedia() {
        // Quote detail can be in view mode or edit mode; either is fine for previews.
        let favoriteButton = app.buttons[AccessibilityIdentifiers.QuoteDetail.favoriteButton]
        let editor = app.textViews[AccessibilityIdentifiers.QuoteDetail.textEditor]
        let isReady = favoriteButton.waitForExistence(timeout: 6) || editor.waitForExistence(timeout: 6)
        XCTAssertTrue(isReady, "Quote detail not loaded (favorite button or editor missing)")
    }

    func waitForCaptureLandingLoadedForMedia() {
        let quoteMode = app.buttons[AccessibilityIdentifiers.Capture.modeSelectQuote]
        assertExists(quoteMode, timeout: 6, "Capture landing not loaded (quote mode button missing)")
    }

    func openFirstBookDetailForMedia() {
        // Try list row first
        let bookRow = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Library.bookListRow)
            .firstMatch
        if bookRow.waitForExistence(timeout: 3) {
            bookRow.tap()
        } else {
            // Fallback to grid card
            let bookCard = app.descendants(matching: .any)
                .matching(identifier: AccessibilityIdentifiers.Library.bookCoverCard)
                .firstMatch
            if bookCard.waitForExistence(timeout: 3) {
                bookCard.tap()
            } else {
                // Final fallback: any table cell
                let firstCell = app.tables.cells.firstMatch
                if firstCell.waitForExistence(timeout: 2) {
                    firstCell.tap()
                }
            }
        }

        let title = app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle]
        assertExists(title, timeout: 4, "Book detail title not found")
    }

    func openFirstQuoteDetailForMedia() {
        // Quotes may be below the fold in book detail. Also, with SwiftUI `NavigationLink`,
        // the tappable element may present as a button or as a descendant static text.
        // We scroll until we can find a hittable tap target, then tap via coordinates for reliability.

        // Ensure we're on book detail.
        _ = app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle].waitForExistence(timeout: 2)

        // Start from a predictable position.
        app.swipeDown()

        let found = waitUntil("hittable quote tap target appears", timeout: 12) { [weak self] in
            guard let self else { return false }

            if self.firstHittableQuoteTapTarget() != nil { return true }
            self.app.swipeUp()
            return false
        }
        XCTAssertTrue(found, "Quote card not found or not hittable in book detail")

        guard let tapTarget = firstHittableQuoteTapTarget() else { return }
        tapReliably(tapTarget)

        let editor = app.textViews[AccessibilityIdentifiers.QuoteDetail.textEditor]
        let favoriteButton = app.buttons[AccessibilityIdentifiers.QuoteDetail.favoriteButton]
        let navTitle = app.navigationBars["Quote"]
        let moreMenu = app.buttons[AccessibilityIdentifiers.Common.moreMenuButton]

        // If the first tap didn't navigate, retry once with a coordinate-tap (more reliable for SwiftUI).
        if !favoriteButton.waitForExistence(timeout: 2) && !navTitle.waitForExistence(timeout: 2) {
            tapReliably(tapTarget, forceCoordinateTap: true)
        }

        let isOnDetail = favoriteButton.waitForExistence(timeout: 3) || navTitle.waitForExistence(timeout: 3)
        XCTAssertTrue(isOnDetail, "Quote detail screen not found")

        // For App Store media we want the editing UI visible.
        if !editor.exists {
            if moreMenu.waitForExistence(timeout: 3) {
                moreMenu.tap()
                let edit = app.buttons["Edit"]
                if edit.waitForExistence(timeout: 3) {
                    edit.tap()
                }
            }
        }

        XCTAssertTrue(editor.waitForExistence(timeout: 4), "Quote editor not shown (TextEditor missing)")
    }

    func firstHittableQuoteTapTarget() -> XCUIElement? {
        // Prefer the actual tappable NavigationLink button when available.
        let buttons = app.buttons
            .matching(identifier: AccessibilityIdentifiers.QuoteCard.container)
            .allElementsBoundByIndex
        if let element = buttons.first(where: { $0.exists && $0.isHittable }) {
            return element
        }

        // Prefer quote text, as it's very likely to be hittable even when the container isn't.
        let quoteTexts = app.staticTexts
            .matching(identifier: AccessibilityIdentifiers.QuoteCard.quoteText)
            .allElementsBoundByIndex
        if let element = quoteTexts.first(where: { $0.exists && $0.isHittable }) {
            return element
        }

        // Fallback: container (can appear under different element types).
        let containers = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.QuoteCard.container)
            .allElementsBoundByIndex
        if let element = containers.first(where: { $0.exists && $0.isHittable }) {
            return element
        }

        return nil
    }

    func tapReliably(_ element: XCUIElement, forceCoordinateTap: Bool = false) {
        // Coordinate taps tend to be more reliable with SwiftUI lists and NavigationLinks.
        guard element.exists else { return }
        if element.isHittable && !forceCoordinateTap {
            element.tap()
            return
        }
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    func returnToLibraryRootForMedia() {
        dismissKeyboard()

        // Active search on iPad replaces the tab navigation, so close it before changing tabs.
        let dismissSearch = app.buttons[AccessibilityIdentifiers.Library.dismissSearchButton]
        if dismissSearch.exists && dismissSearch.isHittable {
            dismissSearch.tap()
        }

        // Keep the system Cancel fallbacks for platforms that present one.
        let cancelA = app.buttons["Cancel"]
        let cancelB = app.navigationBars.buttons["Cancel"]
        if cancelA.exists && cancelA.isHittable { cancelA.tap() }
        if cancelB.exists && cancelB.isHittable { cancelB.tap() }

        // Only pop while we're away from the library root. On iPad, the first
        // navigation button at the root is Add, not a back button.
        for _ in 0..<2 {
            if app.navigationBars["Library"].exists {
                break
            }
            if app.navigationBars.buttons.element(boundBy: 0).exists {
                tapBackButton()
            }
        }
        navigateToLibraryTabIfNeeded()
        XCTAssertTrue(
            app.navigationBars["Library"].waitForExistence(timeout: 3),
            "Library root should be restored after dismissing active search"
        )
    }

    func showSearchResultsForMedia(query: String) {
        navigateToLibraryTabIfNeeded()
        let searchField = app.searchFields.firstMatch
        assertExists(searchField, timeout: 4, "Search field not found")
        searchField.tap()
        searchField.typeText(query)
        dismissKeyboard()

        let found = waitForSearchResults(timeout: 6)
        XCTAssertTrue(found, "Expected search results or empty state")
    }

    func showQuoteCaptureCameraForMedia() {
        // Ensure the tab bar is tappable (keyboard can cover it after search).
        dismissKeyboard()

        _ = tapTab(.capture, timeout: 3)

        // For App Store media, capture the "Capture" landing screen (options list). This is stable,
        // looks good in marketing, and avoids simulator camera permission/state flakiness.
        let quoteMode = app.buttons[AccessibilityIdentifiers.Capture.modeSelectQuote]
        assertExists(quoteMode, timeout: 5, "Capture options not visible")
    }

    func openCoverCaptureForMedia() {
        // Assumes we're already on the Capture landing screen.
        let coverMode = app.buttons[AccessibilityIdentifiers.Capture.modeSelectCover]
        assertExists(coverMode, timeout: 5, "Cover capture option not visible")
        coverMode.tap()

        let nav = app.navigationBars["Add Book"]
        let header = app.staticTexts["Add Book"]
        let manualEntryButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'manually'")
        ).firstMatch
        let shown = nav.waitForExistence(timeout: 2) ||
            header.waitForExistence(timeout: 3) ||
            manualEntryButton.exists
        XCTAssertTrue(shown, "Add Book flow not shown")
    }

    func openAddBookFlowForMedia() {
        navigateToLibraryTabIfNeeded()
        dismissKeyboard()

        // Ensure search isn't active (search focus hides trailing toolbar items).
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            let clearText = app.buttons["Clear text"]
            if clearText.exists && clearText.isHittable {
                clearText.tap()
            }
        }

        let cancelA = app.buttons["Cancel"]
        let cancelB = app.navigationBars.buttons["Cancel"]
        if cancelA.exists && cancelA.isHittable { cancelA.tap() }
        if cancelB.exists && cancelB.isHittable { cancelB.tap() }
        dismissKeyboard()

        // The "+" is a toolbar item; it can surface under navigationBars.buttons.
        let addByNavId = app.navigationBars.buttons[AccessibilityIdentifiers.Library.addBookButton]
        let addByAnyId = app.buttons[AccessibilityIdentifiers.Library.addBookButton]
        let addByLabel = app.navigationBars.buttons["Add"]

        if addByNavId.waitForExistence(timeout: 2) && addByNavId.isHittable {
            addByNavId.tap()
        } else if addByAnyId.waitForExistence(timeout: 2) && addByAnyId.isHittable {
            addByAnyId.tap()
        } else if addByLabel.waitForExistence(timeout: 2) && addByLabel.isHittable {
            addByLabel.tap()
        } else if app.navigationBars.buttons.count > 0 {
            app.navigationBars.buttons.element(boundBy: app.navigationBars.buttons.count - 1).tap()
        }

        // The library add button opens the camera-first cover capture flow.
        let captureHeader = app.staticTexts["Add Book"]
        let manualEntryButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'manually'")
        ).firstMatch
        let shown = captureHeader.waitForExistence(timeout: 5) || manualEntryButton.exists
        XCTAssertTrue(shown, "Add Book capture flow not shown")
    }

    func showSettingsForMedia() {
        let closeButton = app.buttons["Close"]
        let cancelButton = app.buttons["Cancel"]
        if closeButton.exists && closeButton.isHittable {
            closeButton.tap()
        } else if cancelButton.exists && cancelButton.isHittable {
            cancelButton.tap()
        }

        _ = tapTab(.settings, timeout: 3)

        // We don't have a single stable identifier for settings root; accept either nav title or a known toggle.
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 4) ||
            app.staticTexts["Settings"].waitForExistence(timeout: 2)
    }

    func waitForSearchResults(timeout: TimeInterval) -> Bool {
        return waitUntil("search results or empty state", timeout: timeout) { [weak self] in
            guard let self else { return false }

            let bookRows = self.app.otherElements.matching(identifier: AccessibilityIdentifiers.Search.bookResultRow)
            let quoteRows = self.app.otherElements.matching(identifier: AccessibilityIdentifiers.Search.quoteResultRow)
            let bookButtons = self.app.buttons.matching(identifier: AccessibilityIdentifiers.Search.bookResultRow)
            let quoteButtons = self.app.buttons.matching(identifier: AccessibilityIdentifiers.Search.quoteResultRow)

            if bookRows.count > 0 || quoteRows.count > 0 || bookButtons.count > 0 || quoteButtons.count > 0 {
                return true
            }

            let noResults = self.app.otherElements[AccessibilityIdentifiers.Search.noResultsView]
            return noResults.exists
        }
    }

    var previewStepPause: TimeInterval {
        let raw = ProcessInfo.processInfo.environment["APP_STORE_PREVIEW_STEP_DELAY"] ?? "1.6"
        return Double(raw) ?? 1.6
    }

    func pause(_ duration: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(duration))
    }
}
