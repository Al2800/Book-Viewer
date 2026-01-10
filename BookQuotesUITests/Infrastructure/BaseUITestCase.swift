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

    /// The application under test.
    var app: XCUIApplication!

    /// Logger for structured test output.
    var logger: UITestLogger!

    /// Screenshot capture helper.
    var screenshots: ScreenshotCapture!

    /// Additional launch arguments beyond the defaults.
    var additionalLaunchArguments: [String] = []

    /// Additional environment variables for the app.
    var launchEnvironment: [String: String] = [:]

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // Initialize app
        app = XCUIApplication()
        app.launchArguments = defaultLaunchArguments + additionalLaunchArguments
        app.launchEnvironment = launchEnvironment

        // Initialize helpers
        logger = UITestLogger(testName: name)
        screenshots = ScreenshotCapture(app: app, testName: name)

        // Launch app
        logger.info("Launching app with arguments: \(app.launchArguments)")
        app.launch()

        // Wait for app to be ready
        waitForAppReady()
    }

    override func tearDown() {
        // Capture failure screenshot if test failed
        if let failureCount = testRun?.failureCount, failureCount > 0 {
            captureFailureScreenshot()
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
    }

    // MARK: - Screenshot Utilities

    /// Capture a failure screenshot and add as attachment.
    private func captureFailureScreenshot() {
        let attachment = screenshots.captureFailure(failureMessage: "Test failed")
        add(attachment)
    }

    /// Capture a screenshot and add as attachment.
    func captureScreenshot(named name: String, description: String? = nil) {
        if let attachment = screenshots.capture(name: name, description: description) {
            add(attachment)
        }
    }

    // MARK: - Wait Utilities

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
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if element.exists && element.isHittable {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        return false
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
                if app.keyboards.buttons["Done"].exists {
                    app.keyboards.buttons["Done"].tap()
                } else if app.keyboards.buttons["Return"].exists {
                    app.keyboards.buttons["Return"].tap()
                }
            }
        }
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
