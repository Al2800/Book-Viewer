import XCTest
import UIKit

@testable import BookQuotes

// MARK: - ImageQualityAnalyzerTests

final class ImageQualityAnalyzerTests: XCTestCase {

    private func solidImage(size: CGSize = CGSize(width: 256, height: 256), gray: CGFloat = 0.5) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor(white: gray, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

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
        // Use a deterministic low-edge image (flat field) so the Laplacian variance is ~0.
        // Fixture images can vary in compression/sharpness and make this test brittle.
        let image = solidImage()

        let result = await analyzer.quickCheck(image: image)
        XCTAssertFalse(result)
    }

    func testQualityIssueDescriptions() {
        let issue = ImageQualityAnalyzer.QualityIssue.tooBlurry(advice: "Hold steady")
        XCTAssertEqual(issue.description, "Image is blurry. Hold steady")
        XCTAssertEqual(issue.icon, "camera.metering.unknown")
    }
}
