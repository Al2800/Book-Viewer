import Foundation

// MARK: - UI Test Configuration

/// Strongly-typed configuration for UI test launch arguments.
///
/// This utility reads `ProcessInfo.processInfo.arguments` to determine
/// which test modes are active. Use this in app code to conditionally
/// enable test behaviors.
///
/// Usage:
/// ```swift
/// if UITestConfiguration.isUITesting {
///     // Use mock data or skip animations
/// }
///
/// if UITestConfiguration.shouldPreloadLibraryTestData {
///     // Seed the library with test books
/// }
/// ```
///
/// Launch arguments are set in UI tests via `XCUIApplication.launchArguments`:
/// ```swift
/// app.launchArguments = ["--uitesting", "--preload-library-test-data"]
/// ```
enum UITestConfiguration {

    // MARK: - Private Helpers

    private static let arguments = ProcessInfo.processInfo.arguments

    private static func hasArgument(_ flag: String) -> Bool {
        arguments.contains(flag)
    }

    private static func valueAfterArgument(_ flag: String) -> String? {
        if let idx = arguments.firstIndex(of: flag), arguments.indices.contains(idx + 1) {
            return arguments[idx + 1]
        }
        return nil
    }

    private static func valueForEqualsArgument(_ flag: String) -> String? {
        // Supports `--flag=value` forms.
        let prefix = flag + "="
        for arg in arguments where arg.hasPrefix(prefix) {
            return String(arg.dropFirst(prefix.count))
        }
        return nil
    }

    private static func value(for flag: String) -> String? {
        valueForEqualsArgument(flag) ?? valueAfterArgument(flag)
    }

    // MARK: - Core Test Mode

    /// Whether the app is running under UI test automation.
    /// Set via `--uitesting` launch argument.
    static var isUITesting: Bool {
        hasArgument("--uitesting")
    }

    /// Whether to reset onboarding completion for UI tests.
    /// Set via `--reset-onboarding` launch argument.
    static var shouldResetOnboarding: Bool {
        hasArgument("--reset-onboarding")
    }

    /// Whether to clear any persisted authentication credentials before a UI test.
    /// Set via `--reset-auth` launch argument.
    static var shouldResetAuthentication: Bool {
        hasArgument("--reset-auth")
    }

    /// Whether to allow skipping authentication during onboarding.
    /// Set via `--skip-auth` launch argument.
    static var shouldSkipAuth: Bool {
        hasArgument("--skip-auth")
    }

    // MARK: - Data Preloading

    /// Whether to preload the library with test books and quotes.
    /// Set via `--preload-library-test-data` launch argument.
    static var shouldPreloadLibraryTestData: Bool {
        hasArgument("--preload-library-test-data")
    }

    /// Whether to preload data optimized for search testing.
    /// Set via `--preload-search-test-data` launch argument.
    static var shouldPreloadSearchTestData: Bool {
        hasArgument("--preload-search-test-data")
    }

    /// Whether to preload a single test book for focused testing.
    /// Set via `--preload-test-book` launch argument.
    static var shouldPreloadTestBook: Bool {
        hasArgument("--preload-test-book")
    }

    /// Whether to start with an empty library (no seeded data).
    /// Set via `--empty-library` launch argument.
    static var shouldStartWithEmptyLibrary: Bool {
        hasArgument("--empty-library")
    }

    // MARK: - Camera Mocking

    /// Whether to use mock camera for testing capture flows.
    /// Set via `--mock-camera` launch argument.
    static var shouldMockCamera: Bool {
        hasArgument("--mock-camera")
    }

    // MARK: - Gemini Response Mocking

    /// Whether to mock Gemini responses with multiple quotes.
    /// Set via `--mock-multiple-quotes` launch argument.
    static var shouldMockMultipleQuotes: Bool {
        hasArgument("--mock-multiple-quotes")
    }

    /// Whether to mock Gemini responses with low confidence scores.
    /// Set via `--mock-low-confidence` launch argument.
    static var shouldMockLowConfidence: Bool {
        hasArgument("--mock-low-confidence")
    }

    /// Deterministic extraction result used to verify review provenance UI.
    /// Set via `--mock-extraction-scenario remote|local-fallback|mixed`.
    static var mockExtractionScenario: String? {
        guard isUITesting, shouldMockCamera,
              let scenario = value(for: "--mock-extraction-scenario"),
              ["remote", "local-fallback", "mixed"].contains(scenario) else {
            return nil
        }
        return scenario
    }

    // MARK: - Animation Control

    /// Whether to disable animations for faster UI tests.
    /// Set via `--disable-animations` launch argument.
    static var shouldDisableAnimations: Bool {
        hasArgument("--disable-animations")
    }

    /// Whether the app is running in App Store media capture mode.
    /// Set via `--app-store-media` launch argument.
    /// Hides UI-test-only controls and keeps the UI clean for screenshots/videos.
    static var isAppStoreMediaMode: Bool {
        hasArgument("--app-store-media")
    }

    // MARK: - App Store Media Routing

    /// Optional routing hint for App Store media capture.
    /// Use `--media-screen <name>` (or `--media-screen=<name>`) to force the initial screen.
    /// Intended for simulator screenshot automation via simctl launch args.
    static var appStoreMediaScreen: String? {
        value(for: "--media-screen")
    }

    /// Whether App Store media capture should open the onboarding subscription step directly.
    static var shouldOpenSubscriptionMediaScreen: Bool {
        isAppStoreMediaMode && appStoreMediaScreen?.lowercased() == "subscription"
    }

    // MARK: - Convenience

    /// Summary of active test configurations for debugging.
    static var debugDescription: String {
        guard isUITesting else { return "Not in UI testing mode" }

        var flags: [String] = ["UI Testing: ON"]

        if shouldPreloadLibraryTestData { flags.append("Library data: preloaded") }
        if shouldPreloadSearchTestData { flags.append("Search data: preloaded") }
        if shouldPreloadTestBook { flags.append("Test book: preloaded") }
        if shouldStartWithEmptyLibrary { flags.append("Library: empty") }
        if shouldResetOnboarding { flags.append("Onboarding: reset") }
        if shouldResetAuthentication { flags.append("Authentication: reset") }
        if shouldSkipAuth { flags.append("Auth: skipped") }
        if shouldMockCamera { flags.append("Camera: mocked") }
        if shouldMockMultipleQuotes { flags.append("Gemini: multiple quotes") }
        if shouldMockLowConfidence { flags.append("Gemini: low confidence") }
        if let mockExtractionScenario { flags.append("Extraction: \(mockExtractionScenario)") }
        if shouldDisableAnimations { flags.append("Animations: disabled") }
        if isAppStoreMediaMode { flags.append("App Store media mode") }

        return flags.joined(separator: ", ")
    }
}

// MARK: - Test Data Seeding Protocol

/// Protocol for services that can seed test data.
protocol UITestDataSeeding {
    /// Seed data for UI testing based on current configuration.
    func seedTestDataIfNeeded() async throws
}
