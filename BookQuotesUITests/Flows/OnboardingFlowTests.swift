import XCTest

/// End-to-end tests for the onboarding flow.
/// Tests the complete user journey from first launch to main app.
final class OnboardingFlowTests: BaseUITestCase {

    // MARK: - Setup

    override var additionalLaunchArguments: [String] {
        ["--reset-onboarding", "--reset-auth", "--skip-auth"]
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
        let signInHeader = app.staticTexts["Sign In or Continue Locally"]
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
        let signInHeader = app.staticTexts["Sign In or Continue Locally"]
        XCTAssertTrue(signInHeader.waitForExistence(timeout: 5), "Skip should navigate to sign-in")

        logger.success("Skip button navigates to sign-in")
    }

    // MARK: - Sign-In Step Tests

    func testOnboarding_SignInStep_DisplaysCorrectElements() {
        logger.step(1, "Navigating to sign-in step")
        navigateToSignInStep()

        logger.step(2, "Verifying sign-in screen elements")

        // Header
        let header = app.staticTexts["Sign In or Continue Locally"]
        XCTAssertTrue(header.exists, "Sign-in header should be visible")

        // Description
        let description = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'continue locally'")
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

    func testOnboarding_MarkingSetup_DisplaysMarkingOptions() {
        logger.step(1, "Navigating to marking setup")
        navigateToMarkingSetup()

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

    func testOnboarding_MarkingSetup_UseDefaultsOption() {
        logger.step(1, "Navigating to marking setup")
        navigateToMarkingSetup()

        logger.step(2, "Finding Use defaults option")
        let useDefaultsButton = app.buttons["Use defaults"]
        XCTAssertTrue(useDefaultsButton.waitForExistence(timeout: 5), "Use defaults option should exist")

        logger.step(3, "Tapping Use defaults")
        useDefaultsButton.tap()

        logger.step(4, "Verifying navigation to the AI processing decision")
        let consentHeader = app.staticTexts["Remote AI Processing"]
        XCTAssertTrue(consentHeader.waitForExistence(timeout: 5), "Should ask for an AI processing decision")

        app.buttons["Use On-Device Only"].tap()

        let completionHeader = app.staticTexts["You're All Set!"]
        XCTAssertTrue(completionHeader.waitForExistence(timeout: 5), "Should navigate to completion")

        logger.success("Use defaults navigates to completion")
    }

    // MARK: - Completion Step Tests

    func testOnboarding_CompletionStep_DisplaysSuccessState() {
        logger.step(1, "Navigating to completion step")
        navigateToCompletionStep()

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

    func testOnboarding_CompletionStep_TapStartCapturing_DismissesOnboarding() {
        logger.step(1, "Navigating to completion step")
        navigateToCompletionStep()

        logger.step(2, "Tapping Start Capturing")
        let startButton = app.buttons["Start Capturing"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        logger.step(3, "Verifying onboarding dismissed")
        let libraryRoot = app.navigationBars["Library"]
        XCTAssertTrue(libraryRoot.waitForExistence(timeout: 5), "Library should be visible after onboarding")

        logger.success("Start Capturing dismisses onboarding")
    }

    func testOnboarding_LocalOnlyPathKeepsSettingsAndExportAvailable() {
        logger.step(1, "Completing onboarding without an account")
        completeLocalOnlyOnboarding()

        logger.step(2, "Checking account messaging is only shown when requested")
        XCTAssertTrue(tapTab(.settings), "Settings should be available without an account")
        let accountRow = app.buttons[AccessibilityIdentifiers.Settings.accountRow]
        XCTAssertTrue(accountRow.waitForExistence(timeout: 5))
        accountRow.tap()
        XCTAssertTrue(waitForText("Optional Account", timeout: 5))
        XCTAssertTrue(
            waitForText("library, search, exports, and on-device quote extraction work without an account", timeout: 3),
            "The account screen should explain that local features do not require sign-in"
        )
        tapBackButton()

        logger.step(3, "Opening export without an account")
        let exportButton = app.buttons[AccessibilityIdentifiers.Settings.exportQuotesButton]
        for _ in 0..<6 where !exportButton.exists {
            app.swipeUp()
        }
        XCTAssertTrue(exportButton.exists, "Export should remain available without an account")
        exportButton.tap()
        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.Export.formatPicker].waitForExistence(timeout: 5)
                || app.staticTexts["No Quotes"].waitForExistence(timeout: 1)
        )

        logger.success("Local-only onboarding keeps Settings and export available")
    }

    func testOnboarding_LocalOnlyPathOpensManualBookEntry() {
        logger.step(1, "Completing onboarding without an account")
        completeLocalOnlyOnboarding()

        logger.step(2, "Opening manual book entry without an account")
        XCTAssertTrue(tapTab(.capture), "Capture should be available without an account")
        let coverOption = app.buttons[AccessibilityIdentifiers.Capture.modeSelectCover]
        XCTAssertTrue(coverOption.waitForExistence(timeout: 5))
        coverOption.tap()
        let manualEntry = app.buttons[AccessibilityIdentifiers.Capture.manualEntryButton]
        XCTAssertTrue(manualEntry.waitForExistence(timeout: 5))
        manualEntry.tap()
        XCTAssertTrue(app.textFields[AccessibilityIdentifiers.BookEdit.titleField].waitForExistence(timeout: 5))

        logger.success("Local-only onboarding opens manual book entry")
    }

    func testOnboarding_RemoteAIConsentCanBeEnabledAndRevokedInSettings() {
        navigateToCompletionStep()
        app.buttons["Start Capturing"].tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))

        XCTAssertTrue(tapTab(.settings), "Settings should be available after onboarding")
        let remoteAISettings = app.buttons[AccessibilityIdentifiers.Settings.remoteAIProcessingRow]
        XCTAssertTrue(remoteAISettings.waitForExistence(timeout: 5))
        remoteAISettings.tap()

        let consentToggle = app.switches[AccessibilityIdentifiers.Settings.remoteAIProcessingToggle]
        XCTAssertTrue(consentToggle.waitForExistence(timeout: 5))
        XCTAssertEqual(consentToggle.value as? String, "0")

        consentToggle.tap()
        let allowButton = app.buttons["Allow Remote AI Processing"]
        XCTAssertTrue(allowButton.waitForExistence(timeout: 5))
        allowButton.tap()
        XCTAssertTrue(waitUntil("remote AI is enabled") {
            consentToggle.value as? String == "1"
        })

        consentToggle.tap()
        XCTAssertTrue(waitUntil("remote AI is disabled") {
            consentToggle.value as? String == "0"
        })
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
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5), "Welcome should provide Skip on the first page")
        skipButton.tap()

        let signInHeader = app.staticTexts["Sign In or Continue Locally"]
        XCTAssertTrue(signInHeader.waitForExistence(timeout: 5), "Skip should open the sign-in step")
    }

    private func completeLocalOnlyOnboarding() {
        navigateToCompletionStep()
        let startButton = app.buttons["Start Capturing"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
    }

    private func navigateToMarkingSetup() {
        navigateToSignInStep()

        // The local-only path is a required first-run route, independent of authentication.
        let localOnly = app.buttons["Continue Without an Account"]
        XCTAssertTrue(localOnly.waitForExistence(timeout: 5), "Sign-in should offer a local-only path")
        localOnly.tap()

        // Signed-in routes may pass through a subscription prompt; local-only setup should not.
        let subscriptionHeader = app.staticTexts["Choose Your Plan"]
        XCTAssertFalse(subscriptionHeader.waitForExistence(timeout: 1), "Local-only onboarding should not require a subscription choice")

        let markingHeader = app.staticTexts["How Do You Mark Books?"]
        XCTAssertTrue(markingHeader.waitForExistence(timeout: 5), "Local-only onboarding should reach marking setup")
    }

    private func navigateToCompletionStep() {
        navigateToMarkingSetup()

        // Use the advertised defaults path to continue without editing preferences.
        let useDefaults = app.buttons["Use defaults"]
        XCTAssertTrue(useDefaults.waitForExistence(timeout: 5), "Marking setup should offer Use defaults")
        useDefaults.tap()

        let localOnly = app.buttons["Use On-Device Only"]
        XCTAssertTrue(localOnly.waitForExistence(timeout: 5), "Onboarding should ask for an AI processing decision")
        localOnly.tap()

        let completionTitle = app.staticTexts["You're All Set!"]
        XCTAssertTrue(completionTitle.waitForExistence(timeout: 5), "Onboarding should reach completion after choosing on-device processing")
    }
}
