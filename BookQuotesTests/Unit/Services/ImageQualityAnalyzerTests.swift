import XCTest
import UIKit

@testable import BookQuotes

// MARK: - ImageQualityAnalyzerTests

final class ImageQualityAnalyzerTests: XCTestCase {

    func testAnalyzeInvalidImageThrows() async {
        let analyzer = ImageQualityAnalyzer()

        do {
            _ = try await analyzer.analyze(image: UIImage())
            XCTFail("Expected invalid image error")
        } catch let error as QualityAnalysisError {
            XCTAssertEqual(error.errorDescription, "Invalid or corrupted image data")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testQuickCheckRejectsBlurryImage() async {
        let analyzer = ImageQualityAnalyzer(configuration: .strict)
        let imageData = TestFixtures.TestImages.blurryPage
        let image = UIImage(data: imageData) ?? UIImage()

        let result = await analyzer.quickCheck(image: image)
        XCTAssertFalse(result)
    }

    func testQualityIssueDescriptions() {
        let issue = ImageQualityAnalyzer.QualityIssue.tooBlurry(advice: "Hold steady")
        XCTAssertEqual(issue.description, "Image is blurry. Hold steady")
        XCTAssertEqual(issue.icon, "camera.metering.unknown")
    }
}
