import SwiftData
import UIKit
import XCTest

@testable import BookQuotes

@MainActor
final class BatchCapturePageStoreTests: SwiftDataTestCase {

    func testAppendCaptureStoresImageThumbnailOrderAndQualityScore() async throws {
        let book = TestFixtures.atomicHabits
        let session = CaptureSession(book: book)
        modelContext.insert(book)
        modelContext.insert(session)
        try modelContext.save()

        let scores = ScoreQueue([0.82, 0.74])
        let store = BatchCapturePageStore(
            modelContext: modelContext,
            analyzeQuality: { _ in
                Self.qualityResult(score: await scores.next())
            }
        )
        let first = try await store.appendCapture(
            to: session,
            image: testImage(fill: .white),
            previewSize: nil,
            cropBehavior: .none
        )
        let second = try await store.appendCapture(
            to: session,
            image: testImage(fill: .systemGray6),
            previewSize: nil,
            cropBehavior: .none
        )

        XCTAssertEqual(session.totalPages, 2)
        XCTAssertEqual(session.captures.map(\.id), [first.capture.id, second.capture.id])
        XCTAssertEqual(first.capture.orderIndex, 0)
        XCTAssertEqual(second.capture.orderIndex, 1)
        XCTAssertEqual(first.capture.status, .pending)
        XCTAssertEqual(second.capture.status, .pending)
        XCTAssertEqual(first.capture.qualityScore, 0.82)
        XCTAssertEqual(second.capture.qualityScore, 0.74)
        XCTAssertEqual(first.quality?.overallScore, 0.82)
        XCTAssertEqual(second.quality?.overallScore, 0.74)
        XCTAssertNotNil(first.capture.thumbnailData)
        XCTAssertNotNil(second.capture.thumbnailData)
        XCTAssertTrue(FileManager.default.fileExists(atPath: try XCTUnwrap(first.capture.imageURL).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: try XCTUnwrap(second.capture.imageURL).path))
    }

    func testAppendCaptureToleratesFailedQualityAnalysis() async throws {
        let book = TestFixtures.atomicHabits
        let session = CaptureSession(book: book)
        modelContext.insert(book)
        modelContext.insert(session)
        try modelContext.save()

        let store = BatchCapturePageStore(
            modelContext: modelContext,
            analyzeQuality: { _ in nil }
        )
        let result = try await store.appendCapture(
            to: session,
            image: testImage(fill: .white),
            previewSize: nil,
            cropBehavior: .none
        )

        XCTAssertNil(result.quality)
        XCTAssertNil(result.capture.qualityScore)
        XCTAssertEqual(session.totalPages, 1)
    }

    private nonisolated static func qualityResult(score: Double) -> ImageQualityAnalyzer.QualityResult {
        ImageQualityAnalyzer.QualityResult(
            overallScore: score,
            blurScore: 200,
            brightnessScore: 0.5,
            textConfidence: 0.9,
            textRegionCount: 3,
            issues: [],
            isAcceptable: true
        )
    }

    private actor ScoreQueue {
        private var scores: [Double]

        init(_ scores: [Double]) {
            self.scores = scores
        }

        func next() -> Double {
            scores.removeFirst()
        }
    }

    private func testImage(fill: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 180))
        return renderer.image { context in
            fill.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 120, height: 180))
            UIColor.black.setFill()
            context.cgContext.fill(CGRect(x: 18, y: 40, width: 84, height: 8))
            context.cgContext.fill(CGRect(x: 18, y: 58, width: 70, height: 8))
        }
    }
}
