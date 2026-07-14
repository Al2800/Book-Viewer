import XCTest

// MARK: - Base UI Test Case

/// Base class for all UI tests providing common setup, teardown, and utilities.
///
/// Subclass this for consistent test behavior:
/// - Automatic app launch with `--uitesting` argument
/// - Screenshot on failure
/// - Structured logging
/// - Common wait utilities
///
/// ```swift
/// final class MyFlowTests: BaseUITestCase {
///     func testMyFlow() {
///         logger.step(1, "Navigate to screen")
///         // ... test code
///     }
/// }
/// ```
class BaseUITestCase: XCTestCase {

    // MARK: - Properties

    /// Keep references to interruption monitors so they remain active.
    private var interruptionMonitors: [NSObjectProtocol] = []

    /// The application under test.
    var app: XCUIApplication!

    /// Logger for structured test output.
    var logger: UITestLogger!

    /// Screenshot capture helper.
    var screenshots: ScreenshotCapture!

    /// Additional launch arguments beyond the defaults.
    var additionalLaunchArguments: [String] { [] }

    /// Additional environment variables for the app.
    var launchEnvironment: [String: String] { [:] }

    enum UITestTab {
        case library
        case capture
        case settings

        var identifier: String {
            switch self {
            case .library: return AccessibilityIdentifiers.Tabs.libraryTab
            case .capture: return AccessibilityIdentifiers.Tabs.captureTab
            case .settings: return AccessibilityIdentifiers.Tabs.settingsTab
            }
        }

        var label: String {
            switch self {
            case .library: return "Library"
            case .capture: return "Capture"
            case .settings: return "Settings"
            }
        }
    }

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // Initialize app
        app = XCUIApplication()
        app.launchArguments = defaultLaunchArguments + additionalLaunchArguments
        app.launchEnvironment = launchEnvironment

        // Initialize helpers
        screenshots = ScreenshotCapture(app: app, testName: name)
        let captureCheckpoints = ProcessInfo.processInfo.environment["CAPTURE_UI_TEST_CHECKPOINTS"] != nil
        logger = UITestLogger(testName: name) { [weak self] step, message in
            guard captureCheckpoints else { return }
            _ = self?.screenshots.capture(
                name: "step_\(step)",
                description: message
            )
        }

        installSystemInterruptionMonitors()

        // Launch app
        logger.info("Launching app with arguments: \(app.launchArguments)")
        app.launch()

        // Attempt to clear any system permission alerts that can block automation.
        // This is best-effort; on some simulator/OS versions AX may still be flaky.
        // App Store media runs mock camera and avoid permission prompts; SpringBoard alert queries can
        // hang on iOS 26 simulator builds, so skip the sweep in that mode and rely on interruption monitors.
        if !app.launchArguments.contains("--app-store-media") {
            sweepSpringboardAlerts()
        }
        app.tap()

        // Wait for app to be ready
        waitForAppReady()
    }

    override func tearDown() {
        // Capture failure screenshot if test failed
        if let failureCount = testRun?.failureCount, failureCount > 0 {
            logger.error("Test failed with \(failureCount) failure(s)")
            captureFailureScreenshot()
            captureFailureHierarchy()
        }

        // Print log summary
        print(logger.summary())

        // Optionally write to file
        if ProcessInfo.processInfo.environment["WRITE_UI_TEST_LOGS"] != nil {
            logger.writeSummaryToFile()
        }

        app = nil
        logger = nil
        screenshots = nil
        interruptionMonitors.removeAll()

        super.tearDown()
    }

    // MARK: - Launch Arguments

    /// Default launch arguments for UI testing.
    var defaultLaunchArguments: [String] {
        [
            "--uitesting",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
    }

    // MARK: - App Ready Check

    /// Wait for the app to be ready for interaction.
    /// Override to customize the ready check.
    func waitForAppReady() {
        // Default: wait for any tab bar or navigation bar
        let tabBar = app.tabBars.firstMatch
        let navBar = app.navigationBars.firstMatch

        let exists = tabBar.waitForExistence(timeout: 5) || navBar.waitForExistence(timeout: 2)

        if exists {
            logger.info("App ready")
        } else {
            logger.warning("App may not be fully ready (no tab/nav bar found)")
        }

        waitForSeedDataIfNeeded()
    }

    private var shouldWaitForSeedData: Bool {
        app.launchArguments.contains("--preload-library-test-data") ||
        app.launchArguments.contains("--preload-search-test-data") ||
        app.launchArguments.contains("--preload-test-book")
    }

    private func waitForSeedDataIfNeeded() {
        guard shouldWaitForSeedData else { return }

        let seedMarker = app.staticTexts[AccessibilityIdentifiers.Common.uiTestSeeded]
        if seedMarker.waitForExistence(timeout: 15) {
            logger.info("Seeded data ready")
            logSeededBookCountIfAvailable()
        } else {
            let fallbackMarker = app.otherElements[AccessibilityIdentifiers.Common.uiTestSeeded]
            if fallbackMarker.waitForExistence(timeout: 2) {
                logger.info("Seeded data ready")
                logSeededBookCountIfAvailable()
                return
            }
            let seededBook = app.staticTexts[UITestData.Books.atomicHabitsTitle]
            if seededBook.waitForExistence(timeout: 5) {
                logger.info("Seeded data visible without marker")
                logSeededBookCountIfAvailable()
            } else {
                logger.warning("Seed marker not found after timeout")
            }
        }
    }

	    private func logSeededBookCountIfAvailable() {
	        let bookCountLabel = app.staticTexts[AccessibilityIdentifiers.Common.uiTestBookCount]
	        // Avoid adding repeated multi-second waits to every test run.
	        if bookCountLabel.waitForExistence(timeout: 0.2) {
	            logger.info("Seeded book count: \(bookCountLabel.label)")
	        }
	    }

    // MARK: - Screenshot Utilities

    /// Capture a failure screenshot and add as attachment.
    private func captureFailureScreenshot() {
        let attachment = screenshots.captureFailure(failureMessage: "Test failed")
        add(attachment)
    }

    /// Capture the current view hierarchy as a text attachment for debugging failures.
    private func captureFailureHierarchy() {
        // Keep size bounded so CI attachments remain usable.
        let maxChars = 200_000
        var hierarchy = app.debugDescription
        if hierarchy.count > maxChars {
            hierarchy = String(hierarchy.prefix(maxChars)) + "\n\n… (truncated to \(maxChars) chars)"
        }

        let attachment = XCTAttachment(string: hierarchy)
        attachment.name = "ViewHierarchy"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Capture a screenshot and add as attachment.
    func captureScreenshot(named name: String, description: String? = nil) {
        if let attachment = screenshots.capture(name: name, description: description) {
            add(attachment)
        }
    }

    // MARK: - Wait Utilities

    /// Wait for an arbitrary condition to become true.
    ///
    /// Uses `XCTNSPredicateExpectation` to avoid fixed sleeps and to integrate with XCTest's waiting.
    @discardableResult
    func waitUntil(
        _ description: String,
        timeout: TimeInterval = 5,
        file: StaticString = #file,
        line: UInt = #line,
        condition: @escaping () -> Bool
    ) -> Bool {
        let predicate = NSPredicate { _, _ in
            condition()
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        if result != .completed {
            logger.warning("Timeout waiting for condition: \(description) (timeout=\(timeout)s)")
            return false
        }
        return true
    }

    // MARK: - Permission Handling

    private func installSystemInterruptionMonitors() {
        let token = addUIInterruptionMonitor(withDescription: "System permission alerts") { [weak self] alert in
            guard let self else { return false }

            // Prefer allowing permissions so flows can proceed (mock camera may still show prompts).
            let allowLabels = [
                "Allow While Using App",
                "Allow Once",
                "Allow",
                "OK"
            ]
            for label in allowLabels {
                let button = alert.buttons[label]
                if button.exists {
                    self.logger.info("Dismissing system alert by tapping '\(label)'")
                    button.tap()
                    return true
                }
            }

            // Fallback: decline to avoid the alert blocking the run forever.
            let denyLabels = [
                "Don’t Allow",
                "Don't Allow",
                "Not Now"
            ]
            for label in denyLabels {
                let button = alert.buttons[label]
                if button.exists {
                    self.logger.warning("Dismissing system alert by tapping '\(label)'")
                    button.tap()
                    return true
                }
            }

            return false
        }

        interruptionMonitors.append(token)
    }

    /// Best-effort dismissal of in-app alerts that can block UI flows (e.g. error alerts).
    /// Returns true if an alert was found and a button was tapped.
    @discardableResult
    func dismissAppAlertIfPresent() -> Bool {
        let alert = app.alerts.firstMatch
        guard alert.exists else { return false }

        // Prefer allow/ok style buttons.
        let preferredLabels = ["OK", "Allow", "Continue", "Done"]
        for label in preferredLabels {
            let button = alert.buttons[label]
            if button.exists {
                logger.info("App alert: tapping '\(label)'")
                button.tap()
                return true
            }
        }

        // Fallback: try any visible button to avoid blocking the run.
        if alert.buttons.count > 0 {
            let button = alert.buttons.firstMatch
            if button.exists {
                logger.warning("App alert: tapping first button '\(button.label)'")
                button.tap()
                return true
            }
        }

        return false
    }

    /// Best-effort: tap through SpringBoard alerts that can block automation (camera/photos prompts).
    private func sweepSpringboardAlerts() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        guard alert.exists else { return }

        // Try the same allow-first strategy as the interruption monitor.
        let allowLabels = [
            "Allow While Using App",
            "Allow Once",
            "Allow",
            "OK"
        ]
        for label in allowLabels {
            let button = alert.buttons[label]
            if button.exists {
                logger.info("SpringBoard alert: tapping '\(label)'")
                button.tap()
                return
            }
        }

        let denyLabels = [
            "Don’t Allow",
            "Don't Allow",
            "Not Now"
        ]
        for label in denyLabels {
            let button = alert.buttons[label]
            if button.exists {
                logger.warning("SpringBoard alert: tapping '\(label)'")
                button.tap()
                return
            }
        }
    }

    /// Wait for an element to exist.
    /// - Parameters:
    ///   - element: The element to wait for.
    ///   - timeout: Maximum time to wait.
    ///   - message: Optional failure message.
    /// - Returns: Whether the element exists.
    @discardableResult
    func waitForElement(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        message: String? = nil
    ) -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        if !exists, let message = message {
            logger.warning("Element not found: \(message)")
        }
        return exists
    }

    /// Wait for an element to be hittable (visible and enabled).
    /// - Parameters:
    ///   - element: The element to wait for.
    ///   - timeout: Maximum time to wait.
    /// - Returns: Whether the element is hittable.
    @discardableResult
    func waitForHittable(
        _ element: XCUIElement,
        timeout: TimeInterval = 5
    ) -> Bool {
        // KVC keys for predicate evaluation: `exists`, `hittable`, `enabled`.
        let predicate = NSPredicate(format: "exists == true && hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        if result != .completed {
            logger.warning("Element not hittable after timeout=\(timeout)s. elementLabel='\(element.label)' elementId='\(element.identifier)'")
            return false
        }
        return true
    }

    /// Wait for text to appear anywhere on screen.
    /// - Parameters:
    ///   - text: The text to find.
    ///   - timeout: Maximum time to wait.
    /// - Returns: Whether the text was found.
    @discardableResult
    func waitForText(_ text: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let element = app.staticTexts.matching(predicate).firstMatch
        return element.waitForExistence(timeout: timeout)
    }

    // MARK: - Navigation Utilities

    /// Navigate to a tab by name.
    /// - Parameter tabName: The accessibility label of the tab.
    func navigateToTab(_ tabName: String) {
        let tab = app.tabBars.buttons[tabName]
        guard waitForElement(tab, message: "Tab '\(tabName)'") else {
            XCTFail("Tab '\(tabName)' not found")
            return
        }
        tab.tap()
        logger.info("Navigated to tab: \(tabName)")
    }

    func tabButton(_ tab: UITestTab) -> XCUIElement {
        let byIdentifier = app.tabBars.buttons[tab.identifier]
        // Prefer the visible, tappable element. Some tab bar items expose an accessibilityIdentifier
        // on a non-hittable subview, which can yield a valid query with an invalid hit point.
        if byIdentifier.exists && byIdentifier.isHittable {
            return byIdentifier
        }
        return app.tabBars.buttons[tab.label]
    }

    @discardableResult
    func tapTab(_ tab: UITestTab, timeout: TimeInterval = 3, file: StaticString = #file, line: UInt = #line) -> Bool {
        // iPad can present TabView with a different element hierarchy than iPhone. Prefer identifiers,
        // but fall back to labels and broader queries. Coordinate taps are typically more reliable
        // than `.tap()` when isHittable is false on SwiftUI elements.

        let candidates: [XCUIElement] = [
            app.tabBars.buttons[tab.identifier],
            app.buttons[tab.identifier],
            app.tabBars.buttons[tab.label],
            app.buttons[tab.label]
        ]

        for element in candidates {
            if element.waitForExistence(timeout: timeout) {
                if element.isHittable {
                    element.tap()
                } else {
                    element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                }
                return true
            }
        }

        XCTFail("Tab '\(tab.label)' not found", file: file, line: line)
        return false
    }

    /// Tap the back button in navigation.
    func tapBackButton() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists && backButton.isHittable {
            backButton.tap()
            logger.info("Tapped back button")
        } else {
            logger.warning("Back button not found or not tappable")
        }
    }

    // MARK: - Keyboard Utilities

	    /// Dismiss keyboard if visible.
	    func dismissKeyboard() {
	        if app.keyboards.firstMatch.exists {
	            // Try tapping outside
	            app.tap()

            // If still visible, try Done/Return
            if app.keyboards.firstMatch.exists {
                let candidates = ["Done", "Return", "Search", "Go", "Hide keyboard"]
                for label in candidates {
                    let button = app.keyboards.buttons[label]
                    if button.exists && button.isHittable {
                        button.tap()
                        break
                    }
                }
            }
	        }
	    }

	    /// Tap the keyboard "Next" button if available.
	    @discardableResult
	    func tapKeyboardNextIfPresent() -> Bool {
	        let next = app.keyboards.buttons["Next"]
	        guard next.exists, next.isHittable else { return false }
	        next.tap()
	        return true
	    }

	    /// Type into whichever control currently owns keyboard focus (no element tapping).
	    func typeTextIntoFocusedField(_ text: String, timeout: TimeInterval = 3, dismissKeyboardAfter: Bool = true) {
	        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: timeout), "Expected keyboard to exist before typing")
	        app.typeText(text)
	        if dismissKeyboardAfter {
	            dismissKeyboard()
	        }
	    }

		    private func textValue(_ element: XCUIElement) -> String {
		        if let value = element.value as? String {
		            return value
		        }
		        return String(describing: element.value ?? "")
		    }

		    /// Best-effort typing that returns success/failure without failing the test.
		    @discardableResult
		    func tryTypeText(_ text: String, into element: XCUIElement, timeout: TimeInterval = 3, dismissKeyboardAfter: Bool = true) -> Bool {
		        guard element.waitForExistence(timeout: timeout) else {
		            logger.warning("Typing failed. element missing label=\(element.label)")
		            return false
		        }
		        for _ in 0..<2 where !element.isHittable {
		            app.swipeUp()
		        }

		        let attempts = 4
		        for _ in 0..<attempts {
		            if element.isHittable {
		                element.tap()
		            } else {
		                element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
		            }

		            if !app.keyboards.firstMatch.waitForExistence(timeout: 1) {
		                element.doubleTap()
		                _ = app.keyboards.firstMatch.waitForExistence(timeout: 1)
		            }

		            let before = textValue(element)
		            app.typeText(text)
		            let after = textValue(element)

		            if dismissKeyboardAfter {
		                dismissKeyboard()
		            }

		            if after != before {
		                return true
		            }
		            if after.contains(text) || after == text {
		                return true
		            }

		            app.tap()
		        }

		        logger.warning("Typing failed. element=\(element.label) value=\(textValue(element))")
		        return false
		    }

		    /// Focus a text field and type text, retrying focus if needed.
		    func typeText(_ text: String, into element: XCUIElement, timeout: TimeInterval = 3, dismissKeyboardAfter: Bool = true) {
		        let ok = tryTypeText(text, into: element, timeout: timeout, dismissKeyboardAfter: dismissKeyboardAfter)
		        XCTAssertTrue(ok, "Failed to type text into element after multiple attempts")
		    }

		    /// Replace existing text in a field with the provided value (best-effort clear + type).
		    func replaceText(_ text: String, in element: XCUIElement, timeout: TimeInterval = 3, dismissKeyboardAfter: Bool = true) {
		        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Expected element to exist before replacing text")

		        if element.isHittable {
		            element.tap()
		        } else {
		            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
		        }
		        _ = app.keyboards.firstMatch.waitForExistence(timeout: 1)

		        // Prefer Select All if available.
		        element.press(forDuration: 1.0)
		        let selectAll = app.menuItems["Select All"]
		        if selectAll.waitForExistence(timeout: 0.5) {
		            selectAll.tap()
		        } else {
		            // Fall back to repeated delete based on current value length.
		            let current = textValue(element)
		            let deleteKey = app.keys["delete"]
		            if deleteKey.exists {
		                let count = min(max(current.count, 0), 200)
		                for _ in 0..<count {
		                    deleteKey.tap()
		                }
		            }
		        }

		        typeTextIntoFocusedField(text, timeout: timeout, dismissKeyboardAfter: dismissKeyboardAfter)
		    }
		}

// MARK: - Common Assertions

extension BaseUITestCase {

    /// Assert that an element exists.
    func assertExists(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        _ message: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, message ?? "Expected element to exist", file: file, line: line)
    }

    /// Assert that text appears on screen.
    func assertTextExists(
        _ text: String,
        timeout: TimeInterval = 5,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let found = waitForText(text, timeout: timeout)
        XCTAssertTrue(found, "Expected text '\(text)' to appear", file: file, line: line)
    }

    /// Assert that we're on a screen with the given navigation title.
    func assertNavigationTitle(
        _ title: String,
        timeout: TimeInterval = 3,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let navBar = app.navigationBars[title]
        let exists = navBar.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, "Expected navigation title '\(title)'", file: file, line: line)
    }
}

// MARK: - UI Test Constants

/// Accessibility identifiers mirrored for UI tests to avoid linking app code.
enum AccessibilityIdentifiers {

    enum Library {
        static let bookCoverCard = "library_book_cover_card"
        static let bookListRow = "library_book_list_row"
        static let emptyState = "library_empty_state"
        static let addBookButton = "library_add_book_button"
        static let filterButton = "library_filter_button"
        static let sortMenu = "library_sort_menu"
        static let viewModeToggle = "library_view_mode_toggle"
    }

    enum Search {
        static let searchField = "search_field"
        static let scopePicker = "search_scope_picker"
        static let bookResultRow = "search_book_result_row"
        static let quoteResultRow = "search_quote_result_row"
        static let noResultsView = "search_no_results"
        static let searchingIndicator = "search_searching"
        static let didYouMeanBanner = "search_did_you_mean_banner"
    }

    enum QuoteCard {
        static let container = "quote_card_container"
        static let quoteText = "quote_card_text"
        static let marginNote = "quote_card_margin_note"
        static let favoriteIndicator = "quote_card_favorite"
        static let markingBadge = "quote_card_marking_badge"
        static let pageNumber = "quote_card_page_number"
        static let confidenceIndicator = "quote_card_confidence"
    }

    enum QuoteDetail {
        static let textEditor = "quote_detail_text_editor"
        static let pageField = "quote_detail_page_field"
        static let marginNoteField = "quote_detail_margin_note_field"
        static let editButton = "quote_detail_edit_button"
        static let doneButton = "quote_detail_done_button"
        static let cancelButton = "quote_detail_cancel_button"
        static let deleteButton = "quote_detail_delete_button"
        static let favoriteButton = "quote_detail_favorite_button"
        static let copyButton = "quote_detail_copy_button"
        static let shareButton = "quote_detail_share_button"
        static let sourceImageButton = "quote_detail_source_image_button"
        static let markingPickerButton = "quote_detail_marking_picker"
    }

    enum BookEdit {
        static let titleField = "book_edit_title_field"
        static let authorField = "book_edit_author_field"
        static let subtitleField = "book_edit_subtitle_field"
        static let isbnField = "book_edit_isbn_field"
        static let publisherField = "book_edit_publisher_field"
        static let cancelButton = "book_edit_cancel_button"
        static let saveButton = "book_edit_save_button"
    }

    enum Capture {
        static let captureButton = "capture_button"
        static let cameraPreview = "capture_camera_preview"
        static let qualityToggle = "capture_quality_toggle"
        static let cancelButton = "capture_cancel_button"
        static let permissionPrompt = "capture_permission_prompt"
        static let openSettingsButton = "capture_open_settings_button"
        static let testImageButton = "capture_test_image_button"
        static let testCoverButton = "capture_test_cover_button"
        static let modeSelectCover = "capture_mode_select_cover"
        static let modeSelectQuote = "capture_mode_select_quote"
        static let modeSelectBatch = "capture_mode_select_batch"
        static let bookSelectionCard = "capture_book_selection_card"
        static let modePicker = "capture_mode_picker"
        static let pageCounter = "capture_page_counter"
        static let doneButton = "capture_done_button"
        static let thumbnailStrip = "capture_thumbnail_strip"

        // Extraction review (quote capture)
        static let extractionQuoteEditButton = "capture_extraction_quote_edit_button"
        static let extractionQuoteTextEditor = "capture_extraction_quote_text_editor"
        static let extractionQuoteMarginNoteField = "capture_extraction_quote_margin_note_field"

        static let extractionQuoteSourceLabel = "capture_extraction_quote_source_label"

        static let extractionFallbackNotice = "capture_extraction_fallback_notice"
    }

    enum Collections {
        static let addButton = "collections_add_button"
        static let collectionRow = "collections_row"
        static let createButton = "collections_create_button"
        static let nameField = "collections_name_field"
        static let detailView = "collections_detail_view"
        static let emptyState = "collections_empty_state"
    }

    enum Tags {
        static let addButton = "tags_add_button"
        static let tagChip = "tags_chip"
        static let nameField = "tags_name_field"
        static let listView = "tags_list_view"
        static let emptyState = "tags_empty_state"
    }

    enum ImageReview {
        static let imagePreview = "image_review_preview"
        static let retakeButton = "image_review_retake_button"
        static let usePhotoButton = "image_review_use_photo_button"
        static let qualityBar = "image_review_quality_bar"
        static let cancelButton = "image_review_cancel_button"
    }

    enum CoverCrop {
        static let retakeButton = "cover_crop_retake_button"
        static let useCropButton = "cover_crop_use_button"
    }

    enum Export {
        static let exportButton = "export_button"
        static let formatPicker = "export_format_picker"
        static let previewSection = "export_preview"
        static let previewText = "export_preview_text"
        static let shareButton = "export_share_button"
        static let includeBookInfoToggle = "export_include_book_info"
        static let includePageNumbersToggle = "export_include_page_numbers"
    }

    enum BookDetail {
        static let bookTitle = "book_detail_title"
        static let bookAuthor = "book_detail_author"
        static let coverImage = "book_detail_cover_image"
        static let quoteCount = "book_detail_quote_count"
        static let captureQuotesButton = "book_detail_capture_button"
        static let editButton = "book_detail_edit_button"
        static let deleteButton = "book_detail_delete_button"
        static let statusPicker = "book_detail_status_picker"
    }

    enum Onboarding {
        static let continueButton = "onboarding_continue_button"
        static let skipButton = "onboarding_skip_button"
        static let signInButton = "onboarding_sign_in_button"
        static let pageIndicator = "onboarding_page_indicator"
    }

    enum Settings {
        static let accountSection = "settings_account_section"
        static let signOutButton = "settings_sign_out_button"
        static let deleteAccountButton = "settings_delete_account_button"
        static let signInButton = "settings_sign_in_button"
        static let subscriptionStatus = "settings_subscription_status"
        static let restorePurchasesButton = "settings_restore_purchases"
        static let manageSubscriptionButton = "settings_manage_subscription"
        static let markingDefinitionsRow = "settings_marking_definitions_row"
        static let remoteAIProcessingRow = "settings_remote_ai_processing_row"
        static let remoteAIProcessingToggle = "settings_remote_ai_processing_toggle"
        static let exportQuotesButton = "settings_export_quotes_button"
        static let privacyPolicyButton = "settings_privacy_policy_button"
        static let termsOfServiceButton = "settings_terms_of_service_button"
    }

    enum MarkingDefinitions {
        static let listView = "marking_definitions_list_view"
        static let addButton = "marking_definitions_add_button"
        static let markingRow = "marking_definitions_row"
    }

    enum MarkingEditor {
        static let nameField = "marking_editor_name_field"
        static let visualDescriptionField = "marking_editor_visual_description_field"
        static let meaningField = "marking_editor_meaning_field"
        static let saveButton = "marking_editor_save_button"
        static let cancelButton = "marking_editor_cancel_button"
    }

    enum Tabs {
        static let libraryTab = "tab_library"
        static let captureTab = "tab_capture"
        static let settingsTab = "tab_settings"
    }

    enum Common {
        static let loadingIndicator = "loading_indicator"
        static let errorView = "error_view"
        static let retryButton = "retry_button"
        static let dismissButton = "dismiss_button"
        static let moreMenuButton = "more_menu_button"
        static let uiTestSeeded = "ui_test_seeded"
        static let uiTestBookCount = "ui_test_book_count"
    }
}

/// Constants for UI test assertions matching UITestDataSeeder.
enum UITestData {
    enum Books {
        static let atomicHabitsTitle = "Atomic Habits"
        static let atomicHabitsAuthor = "James Clear"
        static let deepWorkTitle = "Deep Work"
        static let deepWorkAuthor = "Cal Newport"
        static let thinkingTitle = "Thinking, Fast and Slow"
        static let thinkingAuthor = "Daniel Kahneman"
        static let testBookTitle = "Test Book"
        static let testBookAuthor = "Test Author"
    }

    enum Quotes {
        static let voteQuote = "Every action you take is a vote for the type of person you wish to become."
        static let systemsQuote = "You do not rise to the level of your goals. You fall to the level of your systems."
        static let compoundQuote = "Habits are the compound interest of self-improvement."
        static let deepWorkQuote = "Deep work is the ability to focus without distraction"
        static let clarityQuote = "Clarity about what matters provides clarity about what does not."
    }

    enum SearchTokens {
        static let improvement = "improvement"
        static let focus = "focus"
        static let mindfulness = "mindfulness"
        static let habits = "habits"
        static let automation = "automation"
    }

    enum Counts {
        static let libraryBooks = 3
        static let libraryQuotes = 6
        static let searchQuotes = 10
        static let testBookQuotes = 3
    }
}
