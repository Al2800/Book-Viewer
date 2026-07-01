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

        let store = BatchCapturePageStore(modelContext: modelContext)
        let first = try await store.appendCapture(
            to: session,
            image: testImage(fill: .white),
            previewSize: nil,
            cropBehavior: .none,
            qualityScore: 0.82
        )
        let second = try await store.appendCapture(
            to: session,
            image: testImage(fill: .systemGray6),
            previewSize: nil,
            cropBehavior: .none,
            qualityScore: 0.74
        )

        XCTAssertEqual(session.totalPages, 2)
        XCTAssertEqual(session.captures.map(\.id), [first.id, second.id])
        XCTAssertEqual(first.orderIndex, 0)
        XCTAssertEqual(second.orderIndex, 1)
        XCTAssertEqual(first.status, .pending)
        XCTAssertEqual(second.status, .pending)
        XCTAssertEqual(first.qualityScore, 0.82)
        XCTAssertEqual(second.qualityScore, 0.74)
        XCTAssertNotNil(first.thumbnailData)
        XCTAssertNotNil(second.thumbnailData)
        XCTAssertTrue(FileManager.default.fileExists(atPath: try XCTUnwrap(first.imageURL).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: try XCTUnwrap(second.imageURL).path))
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
