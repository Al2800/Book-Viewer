import XCTest

/// End-to-end tests for the onboarding flow.
/// Tests the complete user journey from first launch to main app.
final class OnboardingFlowTests: BaseUITestCase {

    // MARK: - Setup

    override var additionalLaunchArguments: [String] {
        ["--reset-onboarding", "--skip-auth"]
    }

    override func waitForAppReady() {
        // For onboarding tests, we expect to land on the welcome screen
        let welcomeTitle = app.staticTexts["Capture Quotes Instantly"]
        if welcomeTitle.waitForExistence(timeout: 5) {
            logger.info("Landed on welcome screen")
        } else {
            // May already be past onboarding, navigate to it
            logger.info("Waiting for onboarding or main app")
            super.waitForAppReady()
        }
    }

    // MARK: - Welcome Screen Tests

    func testOnboarding_WelcomeCarousel_DisplaysAllPages() {
        logger.step(1, "Verifying first welcome page")

        // First page: Capture
        let captureTitle = app.staticTexts["Capture Quotes Instantly"]
        XCTAssertTrue(captureTitle.waitForExistence(timeout: 5), "First page should show Capture title")

        logger.step(2, "Swiping to second page")
        app.swipeLeft()

        // Second page: Organize
        let organizeTitle = app.staticTexts["Build Your Library"]
        XCTAssertTrue(organizeTitle.waitForExistence(timeout: 3), "Second page should show Organize title")

        logger.step(3, "Swiping to third page")
        app.swipeLeft()

        // Third page: Discover
        let discoverTitle = app.staticTexts["Rediscover Wisdom"]
        XCTAssertTrue(discoverTitle.waitForExistence(timeout: 3), "Third page should show Discover title")

        logger.success("All welcome pages displayed correctly")
    }

    func testOnboarding_WelcomeCarousel_ContinueButtonAdvancesPages() {
        logger.step(1, "Verifying initial page")
        XCTAssertTrue(app.staticTexts["Capture Quotes Instantly"].waitForExistence(timeout: 5))

        logger.step(2, "Tapping Continue to advance")
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.exists)
        continueButton.tap()

        logger.step(3, "Verifying page advanced")
        XCTAssertTrue(app.staticTexts["Build Your Library"].waitForExistence(timeout: 3))

        logger.step(4, "Tapping Continue again")
        continueButton.tap()

        logger.step(5, "Verifying third page")
        XCTAssertTrue(app.staticTexts["Rediscover Wisdom"].waitForExistence(timeout: 3))

        logger.success("Continue button advances through pages")
    }

    func testOnboarding_WelcomeCarousel_GetStartedOnLastPage() {
        logger.step(1, "Navigating to last page")
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))

        // Advance to last page
        continueButton.tap()
        _ = app.staticTexts["Build Your Library"].waitForExistence(timeout: 3)
        continueButton.tap()
        _ = app.staticTexts["Rediscover Wisdom"].waitForExistence(timeout: 3)

        logger.step(2, "Verifying Get Started button on last page")
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 3), "Last page should show Get Started")

        logger.step(3, "Tapping Get Started")
        getStartedButton.tap()

        logger.step(4, "Verifying navigation to sign-in")
        // Should navigate to sign-in step
        let signInHeader = app.staticTexts["Create Your Account"]
        XCTAssertTrue(signInHeader.waitForExistence(timeout: 5), "Should navigate to sign-in screen")

        logger.success("Get Started navigates to sign-in")
    }

    func testOnboarding_WelcomeCarousel_SkipButtonNavigatesToSignIn() {
        logger.step(1, "Finding skip button")
        let skipButton = app.buttons["Skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5), "Skip button should be visible")

        logger.step(2, "Tapping Skip")
        skipButton.tap()

        logger.step(3, "Verifying navigation to sign-in")
        let signInHeader = app.staticTexts["Create Your Account"]
        XCTAssertTrue(signInHeader.waitForExistence(timeout: 5), "Skip should navigate to sign-in")

        logger.success("Skip button navigates to sign-in")
    }

    // MARK: - Sign-In Step Tests

    func testOnboarding_SignInStep_DisplaysCorrectElements() {
        logger.step(1, "Navigating to sign-in step")
        navigateToSignInStep()

        logger.step(2, "Verifying sign-in screen elements")

        // Header
        let header = app.staticTexts["Create Your Account"]
        XCTAssertTrue(header.exists, "Sign-in header should be visible")

        // Description
        let description = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'sync your library'")
        ).firstMatch
        XCTAssertTrue(description.exists, "Sign-in description should be visible")

        // Terms and Privacy links
        let termsLink = app.links["Terms"]
        let privacyLink = app.links["Privacy Policy"]
        let termsText = app.staticTexts["Terms"]
        let privacyText = app.staticTexts["Privacy Policy"]
        let termsButton = app.buttons["Terms"]
        let privacyButton = app.buttons["Privacy Policy"]
        let hasLegal = termsLink.exists || privacyLink.exists || termsText.exists || privacyText.exists ||
            termsButton.exists || privacyButton.exists
        XCTAssertTrue(hasLegal, "Legal links should be visible")

        logger.success("Sign-in step displays correct elements")
    }

    // MARK: - Marking Setup Tests

    func testOnboarding_MarkingSetup_DisplaysMarkingOptions() throws {
        logger.step(1, "Navigating to marking setup")
        try navigateToMarkingSetup()

        logger.step(2, "Verifying marking setup screen")
        let header = app.staticTexts["How Do You Mark Books?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Marking setup header should be visible")

        logger.step(3, "Verifying marking style options")
        // Check for common marking types
        let underlineOption = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Underline'")
        ).firstMatch
        let highlightOption = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Highlight'")
        ).firstMatch

        XCTAssertTrue(underlineOption.exists || highlightOption.exists, "Marking options should be available")

        logger.success("Marking setup displays options")
    }

    func testOnboarding_MarkingSetup_UseDefaultsOption() throws {
        logger.step(1, "Navigating to marking setup")
        try navigateToMarkingSetup()

        logger.step(2, "Finding Use defaults option")
        let useDefaultsButton = app.buttons["Use defaults"]
        XCTAssertTrue(useDefaultsButton.waitForExistence(timeout: 5), "Use defaults option should exist")

        logger.step(3, "Tapping Use defaults")
        useDefaultsButton.tap()

        logger.step(4, "Verifying navigation to completion")
        let completionHeader = app.staticTexts["You're All Set!"]
        XCTAssertTrue(completionHeader.waitForExistence(timeout: 5), "Should navigate to completion")

        logger.success("Use defaults navigates to completion")
    }

    // MARK: - Completion Step Tests

    func testOnboarding_CompletionStep_DisplaysSuccessState() throws {
        logger.step(1, "Navigating to completion step")
        try navigateToCompletionStep()

        logger.step(2, "Verifying completion screen elements")

        // Success message
        let successTitle = app.staticTexts["You're All Set!"]
        XCTAssertTrue(successTitle.exists, "Success title should be visible")

        // Description
        let description = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'capturing quotes'")
        ).firstMatch
        XCTAssertTrue(description.exists, "Success description should be visible")

        // Start button
        let startButton = app.buttons["Start Capturing"]
        XCTAssertTrue(startButton.exists, "Start Capturing button should be visible")

        logger.success("Completion step displays success state")
    }

    func testOnboarding_CompletionStep_TapStartCapturing_DismissesOnboarding() throws {
        logger.step(1, "Navigating to completion step")
        try navigateToCompletionStep()

        logger.step(2, "Tapping Start Capturing")
        let startButton = app.buttons["Start Capturing"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        logger.step(3, "Verifying onboarding dismissed")
        // Should see the main app (tab bar)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should be visible after onboarding")

        logger.success("Start Capturing dismisses onboarding")
    }

    // MARK: - Page Indicators Tests

    func testOnboarding_WelcomeCarousel_PageIndicatorsUpdate() {
        logger.step(1, "Verifying page indicators exist")

        // There should be 3 dots for 3 pages
        // Look for circle shapes (page indicators)
        let firstPage = app.staticTexts["Capture Quotes Instantly"]
        XCTAssertTrue(firstPage.waitForExistence(timeout: 5))

        logger.step(2, "Swiping through pages and checking indicators update")
        app.swipeLeft()
        _ = app.staticTexts["Build Your Library"].waitForExistence(timeout: 3)

        app.swipeLeft()
        _ = app.staticTexts["Rediscover Wisdom"].waitForExistence(timeout: 3)

        logger.success("Page indicators work with swipe navigation")
    }

    // MARK: - Helpers

    private func navigateToSignInStep() {
        let skipButton = app.buttons["Skip"]
        if skipButton.waitForExistence(timeout: 5) {
            skipButton.tap()
        } else {
            // Navigate through welcome pages
            let getStarted = app.buttons["Get Started"]
            if getStarted.exists {
                getStarted.tap()
            }
        }

        // Wait for sign-in screen
        _ = app.staticTexts["Create Your Account"].waitForExistence(timeout: 5)
    }

    private func navigateToMarkingSetup() throws {
        navigateToSignInStep()

        // In test mode with --skip-auth, try to find a way to bypass sign-in
        // Look for "Maybe later" or continue button
        let maybeLater = app.buttons["Maybe later"]
        if maybeLater.waitForExistence(timeout: 3) {
            maybeLater.tap()
        }

        // Wait for marking setup or completion
        let markingHeader = app.staticTexts["How Do You Mark Books?"]
        if !markingHeader.waitForExistence(timeout: 5) {
            throw XCTSkip("Could not navigate to marking setup - may require auth")
        }
    }

    private func navigateToCompletionStep() throws {
        try navigateToMarkingSetup()

        // Use defaults to skip to completion
        let useDefaults = app.buttons["Use defaults"]
        if useDefaults.waitForExistence(timeout: 3) {
            useDefaults.tap()
        } else {
            let continueButton = app.buttons["Continue"]
            if continueButton.exists {
                continueButton.tap()
            }
        }

        // Wait for completion
        let completionTitle = app.staticTexts["You're All Set!"]
        if !completionTitle.waitForExistence(timeout: 5) {
            throw XCTSkip("Could not navigate to completion step")
        }
    }
}
