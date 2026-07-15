import XCTest

// MARK: - Screenshot Capture

/// Helper for capturing and managing UI test screenshots.
final class ScreenshotCapture {

    // MARK: - Properties

    private let app: XCUIApplication
    private let testName: String
    private var captureCount = 0
    private let fileManager = FileManager.default

    // MARK: - Initialization

    init(app: XCUIApplication, testName: String) {
        self.app = app
        self.testName = testName
    }

    // MARK: - Capture Methods

    /// Capture a screenshot with an optional description.
    /// - Parameters:
    ///   - name: Optional name for the screenshot.
    ///   - description: Description of what's being captured.
    /// - Returns: The captured screenshot attachment, or nil if capture failed.
    @discardableResult
    func capture(name: String? = nil, description: String? = nil) -> XCTAttachment? {
        captureCount += 1

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)

        let screenshotName = name ?? "screenshot_\(captureCount)"
        attachment.name = "\(sanitizedTestName)_\(screenshotName)"
        attachment.lifetime = .keepAlways

        if let description = description {
            print("📸 Screenshot [\(screenshotName)]: \(description)")
        } else {
            print("📸 Screenshot [\(screenshotName)]")
        }

        saveScreenshot(screenshot, name: screenshotName)

        return attachment
    }

    /// Capture a screenshot on test failure.
    /// - Parameter failureMessage: The failure message to include in the screenshot name.
    /// - Returns: The captured screenshot attachment.
    @discardableResult
    func captureFailure(failureMessage: String? = nil) -> XCTAttachment {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)

        attachment.name = "\(sanitizedTestName)_FAILURE"
        attachment.lifetime = .keepAlways

        if let message = failureMessage {
            print("📸 Failure screenshot: \(message)")
        } else {
            print("📸 Failure screenshot captured")
        }

        saveScreenshot(screenshot, name: "FAILURE")

        return attachment
    }

    /// Capture a screenshot of a specific element.
    /// - Parameters:
    ///   - element: The element to screenshot.
    ///   - name: Name for the screenshot.
    /// - Returns: The captured screenshot attachment, or nil if the element isn't available.
    @discardableResult
    func captureElement(_ element: XCUIElement, name: String) -> XCTAttachment? {
        guard element.exists else {
            print("⚠️ Cannot capture element '\(name)' - element doesn't exist")
            return nil
        }

        let screenshot = element.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)

        attachment.name = "\(sanitizedTestName)_\(name)"
        attachment.lifetime = .keepAlways

        print("📸 Element screenshot [\(name)]")

        saveScreenshot(screenshot, name: name)

        return attachment
    }

    // MARK: - Helpers

    /// Capture the current application screen using XCTest's nonthrowing API.
    /// - Returns: The screenshot attachment.
    func safeCaptureScreen() -> XCTAttachment {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(sanitizedTestName)_safe_capture_\(captureCount)"
        attachment.lifetime = .keepAlways
        captureCount += 1
        saveScreenshot(screenshot, name: "safe_capture_\(captureCount)")
        return attachment
    }

    private var sanitizedTestName: String {
        testName
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }

    private var artifactsDirectory: URL {
        if let customPath = ProcessInfo.processInfo.environment["UI_TEST_ARTIFACTS_DIR"] {
            return URL(fileURLWithPath: customPath, isDirectory: true)
        }
        return fileManager.temporaryDirectory.appendingPathComponent("BookQuotesUITests", isDirectory: true)
    }

    private func saveScreenshot(_ screenshot: XCUIScreenshot, name: String) {
        let screenshotsDir = artifactsDirectory.appendingPathComponent("screenshots", isDirectory: true)
        do {
            try fileManager.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
            let fileName = "\(sanitizedTestName)_\(name).png"
            let fileURL = screenshotsDir.appendingPathComponent(fileName)
            try screenshot.pngRepresentation.write(to: fileURL, options: .atomic)
        } catch {
            print("⚠️ Failed to save screenshot: \(error)")
        }
    }
}

// MARK: - XCUIApplication Extension

extension XCUIApplication {
    /// Take a screenshot and create an attachment.
    func screenshotAttachment(named name: String) -> XCTAttachment {
        let screenshot = self.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        return attachment
    }
}
