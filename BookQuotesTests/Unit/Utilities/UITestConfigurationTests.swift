import XCTest

@testable import BookQuotes

// MARK: - UITestConfigurationTests

final class UITestConfigurationTests: XCTestCase {

    func testDebugDescriptionWhenNotUITesting() {
        XCTAssertEqual(UITestConfiguration.debugDescription, "Not in UI testing mode")
    }
}
