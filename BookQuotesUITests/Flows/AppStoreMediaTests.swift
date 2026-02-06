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

        logger.step(2, "Book detail")
        openFirstBookDetailForMedia()
        captureScreenshot(named: "02_book_detail", description: "Book detail with quotes")

        logger.step(3, "Quote detail")
        openFirstQuoteDetailForMedia()
        captureScreenshot(named: "03_quote_detail", description: "Quote detail editor")

        logger.step(4, "Search results")
        returnToLibraryRootForMedia()
        showSearchResultsForMedia(query: UITestData.SearchTokens.habits)
        captureScreenshot(named: "04_search_results", description: "Search results for seeded quotes")

        logger.step(5, "Capture")
        showQuoteCaptureCameraForMedia()
        captureScreenshot(named: "05_capture", description: "Quote capture camera")
    }
}

// MARK: - App Store Previews

/// Drives an App Store preview flow while a simulator recording is running.
final class AppStorePreviewsTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-search-test-data",
            "--mock-camera",
            "--app-store-media"
        ]
    }

    override func waitForAppReady() {
        super.waitForAppReady()
        navigateToLibraryTabIfNeeded()
    }

    func testPreview_LibraryToQuoteFlow() {
        let stepPause = previewStepPause

        navigateToLibraryTabIfNeeded()
        switchToGridViewIfPossible()
        pause(stepPause)

        openFirstBookDetailForMedia()
        pause(stepPause)

        app.swipeUp()
        pause(stepPause)

        openFirstQuoteDetailForMedia()
        pause(stepPause)

        tapBackButton()
        pause(stepPause)

        showQuoteCaptureCameraForMedia()
        pause(stepPause)
    }
}

// MARK: - Shared Helpers

fileprivate extension BaseUITestCase {
    func navigateToLibraryTabIfNeeded() {
        let libraryTab = tabButton(.library)
        if libraryTab.waitForExistence(timeout: 3) && libraryTab.isHittable {
            libraryTab.tap()
        }
    }

    func switchToGridViewIfPossible() {
        let viewModeToggle = app.segmentedControls[AccessibilityIdentifiers.Library.viewModeToggle]
        guard viewModeToggle.waitForExistence(timeout: 2) else { return }
        if viewModeToggle.buttons.count > 0 {
            viewModeToggle.buttons.element(boundBy: 0).tap()
        }
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
        let quoteCard = app.otherElements
            .matching(identifier: AccessibilityIdentifiers.QuoteCard.container)
            .firstMatch
        if quoteCard.waitForExistence(timeout: 4) {
            quoteCard.tap()
        } else {
            let quoteCell = app.cells
                .matching(identifier: AccessibilityIdentifiers.QuoteCard.container)
                .firstMatch
            if quoteCell.waitForExistence(timeout: 3) {
                quoteCell.tap()
            }
        }

        let editor = app.textViews[AccessibilityIdentifiers.QuoteDetail.textEditor]
        if !editor.waitForExistence(timeout: 4) {
            let favoriteButton = app.buttons[AccessibilityIdentifiers.QuoteDetail.favoriteButton]
            let navTitle = app.navigationBars["Quote"]
            let isOnDetail = favoriteButton.exists || navTitle.exists
            XCTAssertTrue(isOnDetail, "Quote detail screen not found")
        }
    }

    func returnToLibraryRootForMedia() {
        // Try to pop navigation stack if we're in detail views
        for _ in 0..<2 {
            if app.navigationBars.buttons.element(boundBy: 0).exists {
                tapBackButton()
            }
        }
        navigateToLibraryTabIfNeeded()
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
        let captureTab = tabButton(.capture)
        assertExists(captureTab, timeout: 3, "Capture tab not found")
        captureTab.tap()

        let quoteMode = app.buttons[AccessibilityIdentifiers.Capture.modeSelectQuote]
        if quoteMode.waitForExistence(timeout: 4) {
            quoteMode.tap()
        }

        let bookCard = app.buttons[AccessibilityIdentifiers.Capture.bookSelectionCard].firstMatch
        if bookCard.waitForExistence(timeout: 5) {
            bookCard.tap()
        }

        let captureReady =
            app.buttons[AccessibilityIdentifiers.Capture.captureButton].waitForExistence(timeout: 5) ||
            app.otherElements[AccessibilityIdentifiers.Capture.cameraPreview].waitForExistence(timeout: 5)
        XCTAssertTrue(captureReady, "Capture UI not visible")
    }

    func waitForSearchResults(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            let bookRows = app.otherElements.matching(identifier: AccessibilityIdentifiers.Search.bookResultRow)
            let quoteRows = app.otherElements.matching(identifier: AccessibilityIdentifiers.Search.quoteResultRow)
            let bookButtons = app.buttons.matching(identifier: AccessibilityIdentifiers.Search.bookResultRow)
            let quoteButtons = app.buttons.matching(identifier: AccessibilityIdentifiers.Search.quoteResultRow)
            if bookRows.count > 0 || quoteRows.count > 0 || bookButtons.count > 0 || quoteButtons.count > 0 {
                return true
            }

            let noResults = app.otherElements[AccessibilityIdentifiers.Search.noResultsView]
            if noResults.exists {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        return false
    }

    var previewStepPause: TimeInterval {
        let raw = ProcessInfo.processInfo.environment["APP_STORE_PREVIEW_STEP_DELAY"] ?? "1.6"
        return Double(raw) ?? 1.6
    }

    func pause(_ duration: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(duration))
    }
}
