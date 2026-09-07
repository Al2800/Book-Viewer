import XCTest
import SwiftUI

@testable import BookQuotes

@MainActor
final class SourcePageImageStateTests: XCTestCase {
    func testRepeatedLoadsOfSameSourceReuseViewerImage() async {
        let state = SourcePageImageState()
        let image = UIImage()
        let url = URL(fileURLWithPath: "/source.jpg")
        var reads = 0
        let loader: (URL?) async throws -> UIImage = { _ in reads += 1; return image }
        await state.load(from: url, using: loader)
        await state.load(from: url, using: loader)
        XCTAssertEqual(reads, 1)
        XCTAssertTrue(state.image === image)
        XCTAssertFalse(state.isLoading)
    }

    func testMissingSourceClearsPreviousPixelsAndStopsLoading() async {
        let state = SourcePageImageState()
        await state.load(from: URL(fileURLWithPath: "/first.jpg"), using: { _ in UIImage() })
        await state.load(from: nil)
        XCTAssertNil(state.image)
        XCTAssertFalse(state.isLoading)
    }

    func testCancelledUncooperativeLoaderCannotPublishPixels() async {
        let state = SourcePageImageState()
        let started = expectation(description: "Loader suspended")
        var continuation: CheckedContinuation<UIImage, Never>?
        let task = Task {
            await state.load(from: URL(fileURLWithPath: "/cancelled.jpg"), using: { _ in
                await withCheckedContinuation { pending in
                    continuation = pending
                    started.fulfill()
                }
            })
        }
        await fulfillment(of: [started], timeout: 2)
        task.cancel()
        continuation?.resume(returning: UIImage())
        await task.value
        XCTAssertNil(state.image)
        XCTAssertFalse(state.isLoading)
    }

    func testNewSourceWinsOverOlderUncooperativeLoad() async {
        let state = SourcePageImageState()
        let started = expectation(description: "Old load suspended")
        var continuation: CheckedContinuation<UIImage, Never>?
        let old = Task {
            await state.load(from: URL(fileURLWithPath: "/old.jpg"), using: { _ in
                await withCheckedContinuation { pending in
                    continuation = pending
                    started.fulfill()
                }
            })
        }
        await fulfillment(of: [started], timeout: 2)
        let current = UIImage()
        await state.load(from: URL(fileURLWithPath: "/new.jpg"), using: { _ in current })
        continuation?.resume(returning: UIImage())
        await old.value
        XCTAssertTrue(state.image === current)
        XCTAssertFalse(state.isLoading)
    }
}

final class PageQuoteEditorListTests: XCTestCase {

    func testCountTitleUsesSingularAndPluralQuoteLabels() {
        XCTAssertEqual(PageQuoteEditorList(quotes: []).countTitle, "0 Quotes")
        XCTAssertEqual(PageQuoteEditorList(quotes: [quote(text: "One")]).countTitle, "1 Quote")
        XCTAssertEqual(PageQuoteEditorList(quotes: [quote(text: "One"), quote(text: "Two")]).countTitle, "2 Quotes")
    }

    func testDeletingQuoteRemovesOnlyMatchingIdentity() {
        let firstId = UUID()
        let secondId = UUID()
        let sameText = "Same extracted text"
        var list = PageQuoteEditorList(quotes: [
            quote(id: firstId, text: sameText),
            quote(id: secondId, text: sameText)
        ])

        list.delete(quote(id: firstId, text: sameText))

        XCTAssertEqual(list.quotes.map(\.id), [secondId])
    }

    func testReviewGuidancePreservesFiniteScoreBoundaries() {
        for score in [0.0, 0.49] {
            XCTAssertEqual(guidance(score), .checkCarefully)
        }
        for score in [0.5, 0.79] {
            XCTAssertEqual(guidance(score), .checkSource)
        }
        for score in [0.8, 0.95, 1] {
            XCTAssertEqual(guidance(score), .compareWithSource)
        }
    }

    func testMissingAndInvalidConfidenceAreUnavailableNotLowConfidence() {
        let scores: [Double?] = [nil, .nan, .infinity, -.infinity, -0.01, 1.01]
        for score in scores {
            XCTAssertEqual(guidance(score), .unavailable)
        }
        XCTAssertEqual(PassageReviewGuidance.unavailable.color, Color.textSecondary)
    }

    func testManualEntryIsNotPresentedAsAIUncertainty() {
        var candidate = quote(text: "A passage entered manually")
        candidate.isManual = true
        XCTAssertEqual(candidate.reviewGuidance, .manual)
        candidate.isManual = false
        candidate.extractionSource = .manual
        candidate.confidence = 0.1
        XCTAssertEqual(candidate.reviewGuidance, .manual)
    }

    func testEditingDoesNotUpgradeAnUncertainPassageOrChangeSelection() {
        var candidate = quote(text: "A corrected passage")
        candidate.confidence = 0.2
        candidate.isModified = true
        XCTAssertEqual(candidate.reviewGuidance, .checkCarefully)
        let state = ExtractionReviewQuoteState(editingQuotes: [candidate])
        XCTAssertEqual(state.selectedQuotes.map(\.id), [candidate.id], "Guidance must not change selection policy")
    }

    func testHighConfidenceDoesNotClaimVerificationOrSuccess() {
        XCTAssertEqual(PassageReviewGuidance.compareWithSource.title, "Compare with source")
        XCTAssertEqual(PassageReviewGuidance.compareWithSource.color, Color.textSecondary)
        XCTAssertTrue(PassageReviewGuidance.compareWithSource.explanation.contains("not verification"))
        let states: [PassageReviewGuidance] = [.manual, .unavailable, .compareWithSource, .checkSource, .checkCarefully]
        for guidance in states {
            XCTAssertFalse(guidance.title.contains("%"))
            XCTAssertFalse(guidance.explanation.isEmpty)
        }
    }

    private func guidance(_ confidence: Double?) -> PassageReviewGuidance {
        var candidate = quote(text: "An extracted passage")
        candidate.confidence = confidence
        return candidate.reviewGuidance
    }

    func testPassagesPageHeadersUseCaptureOrder() {
        XCTAssertEqual(ExtractionReviewPageHeader.title(orderIndex: 0), "PAGE 1")
        XCTAssertEqual(ExtractionReviewPageHeader.title(orderIndex: 1), "PAGE 2")
    }

    private func quote(id: UUID = UUID(), text: String) -> EditableQuote {
        EditableQuote(
            id: id,
            pageId: UUID(),
            text: text,
            markingType: "underline"
        )
    }
}
