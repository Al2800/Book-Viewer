import XCTest
import SwiftData
import UIKit
import Vision

@testable import BookQuotes

// MARK: - MarkingDefinitionIntegrationTests

@MainActor
final class MarkingDefinitionIntegrationTests: SwiftDataTestCase {

    func testSeedDefaults_CreatesExpectedSystemDefinitionsSorted() throws {
        logger.step(1, "Fetch system defaults (seeded in setUp)")

        let systemOnly = FetchDescriptor<MarkingDefinition>(
            predicate: #Predicate { $0.isSystemDefault },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let definitions = try modelContext.fetch(systemOnly)

        XCTAssertEqual(definitions.count, MarkingDefinition.systemDefaults.count)

        logger.step(2, "Validate content and ordering")
        for (index, definition) in definitions.enumerated() {
            let expected = MarkingDefinition.systemDefaults[index]
            XCTAssertTrue(definition.isSystemDefault)
            XCTAssertTrue(definition.isEnabled)
            XCTAssertEqual(definition.sortOrder, index)

            XCTAssertEqual(definition.name, expected.name)
            XCTAssertEqual(definition.visualDescription, expected.visualDescription)
            XCTAssertEqual(definition.meaning, expected.meaning)
            XCTAssertEqual(definition.icon, expected.icon)
            XCTAssertEqual(definition.colorName, expected.colorName)
        }
    }

    func testSeedDefaults_IsIdempotent() throws {
        logger.step(1, "Measure system default count")
        let systemOnly = FetchDescriptor<MarkingDefinition>(predicate: #Predicate { $0.isSystemDefault })
        let before = try modelContext.fetchCount(systemOnly)
        XCTAssertGreaterThan(before, 0)

        logger.step(2, "Call seedDefaults again and verify count unchanged")
        MarkingDefinition.seedDefaults(in: modelContext)
        try modelContext.save()

        let after = try modelContext.fetchCount(systemOnly)
        XCTAssertEqual(after, before)
    }

    func testCustomDefinition_CRUD_PersistsAndDoesNotAffectSystemDefaults() throws {
        logger.step(1, "Create and insert a custom marking definition")
        let custom = MarkingDefinition(
            name: "Triangle",
            visualDescription: "Triangle drawn in the margin",
            meaning: "Important concept to revisit",
            icon: "triangle",
            colorName: "cyan"
        )
        custom.isEnabled = false
        custom.sortOrder = 999

        modelContext.insert(custom)
        try modelContext.save()

        logger.step(2, "Fetch custom-only and verify fields persisted")
        let customOnly = FetchDescriptor<MarkingDefinition>(
            predicate: #Predicate { !$0.isSystemDefault },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let customs = try modelContext.fetch(customOnly)
        XCTAssertTrue(customs.contains(where: { $0.id == custom.id }))

        let customID = custom.id
        let fetchedCustom = try modelContext.fetch(
            FetchDescriptor<MarkingDefinition>(predicate: #Predicate { $0.id == customID })
        ).first
        XCTAssertEqual(fetchedCustom?.name, "Triangle")
        XCTAssertEqual(fetchedCustom?.icon, "triangle")
        XCTAssertEqual(fetchedCustom?.colorName, "cyan")
        XCTAssertEqual(fetchedCustom?.isEnabled, false)
        XCTAssertEqual(fetchedCustom?.sortOrder, 999)

        logger.step(3, "Update and verify persistence")
        fetchedCustom?.meaning = "Action item"
        fetchedCustom?.isEnabled = true
        fetchedCustom?.sortOrder = 10
        try modelContext.save()

        let updated = try modelContext.fetch(
            FetchDescriptor<MarkingDefinition>(predicate: #Predicate { $0.id == customID })
        ).first
        XCTAssertEqual(updated?.meaning, "Action item")
        XCTAssertEqual(updated?.isEnabled, true)
        XCTAssertEqual(updated?.sortOrder, 10)

        logger.step(4, "Delete custom and verify system defaults remain")
        if let updated {
            modelContext.delete(updated)
            try modelContext.save()
        }

        let deleted = try modelContext.fetch(
            FetchDescriptor<MarkingDefinition>(predicate: #Predicate { $0.id == customID })
        ).first
        XCTAssertNil(deleted)

        let systemCount = try modelContext.fetchCount(
            FetchDescriptor<MarkingDefinition>(predicate: #Predicate { $0.isSystemDefault })
        )
        XCTAssertEqual(systemCount, MarkingDefinition.systemDefaults.count)
    }

    func testQuote_CustomMarkingDefinition_RelationshipPersists() throws {
        logger.step(1, "Insert book + custom definition + quote")
        let book = TestFixtures.book()
        let custom = MarkingDefinition(
            name: "Box",
            visualDescription: "Box drawn around a paragraph",
            meaning: "Definition or reference",
            icon: "square",
            colorName: "orange"
        )

        let quote = Quote(
            text: "A quote long enough to be valid and linked to a custom marking definition.",
            book: book,
            markingType: .underline
        )
        quote.customMarkingDefinition = custom

        modelContext.insert(book)
        modelContext.insert(custom)
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(2, "Fetch and verify inverse relationship")
        let quoteID = quote.id
        let customID = custom.id

        let fetchedQuote = try modelContext.fetch(
            FetchDescriptor<Quote>(predicate: #Predicate { $0.id == quoteID })
        ).first
        XCTAssertEqual(fetchedQuote?.customMarkingDefinition?.id, customID)

        let fetchedDefinition = try modelContext.fetch(
            FetchDescriptor<MarkingDefinition>(predicate: #Predicate { $0.id == customID })
        ).first
        XCTAssertTrue(fetchedDefinition?.quotes.contains(where: { $0.id == quoteID }) ?? false)
    }
}

// MARK: - VisionOCRCoverExtractionIntegrationTests

/// Golden integration tests that run real Vision OCR against synthetic cover fixtures.
///
/// Tolerance rules (to reduce iOS-minor OCR drift):
/// - Compare using lowercase alphanumeric "word" tokens (punctuation/spacing ignored).
/// - Require expected words to be a subset of detected words (allows subtitles, badges, etc).
final class VisionOCRCoverExtractionIntegrationTests: XCTestCase {

    func testVisionOCR_Covers_ProduceExpectedTitleAndAuthorTokens() async throws {
        for cover in TestFixtures.OCRCoverFixtures.all {
            try await assertCover(cover)
        }
    }

    private func assertCover(_ cover: TestFixtures.OCRCoverFixtures.Cover) async throws {
        let lines = try await recognizeTextLines(from: cover.image)

        // Mirror production ordering: top-to-bottom (Vision coordinates), then left-to-right.
        let sorted = lines.sorted { a, b in
            if abs(a.box.midY - b.box.midY) > 0.03 {
                return a.box.midY > b.box.midY
            }
            return a.box.minX < b.box.minX
        }

        let cleaned = sorted
            .map { (text: CoverOCRHeuristics.sanitizeLine($0.text), box: $0.box) }
            .filter { !$0.text.isEmpty }

        let guess = CoverOCRHeuristics.guessTitleAndAuthor(from: cleaned)

        if guess.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            guess.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            let debug = debugDump(cover: cover, rawLines: sorted, cleanedLines: cleaned, guess: guess)
            add(XCTAttachment(string: debug))
            XCTFail("OCR guess unexpectedly empty for fixture id=\(cover.id)")
            return
        }

        // Title: allow subtitles/badges and occasional OCR misses (one missing word for longer titles).
        assertExpectedTitle(
            expected: cover.expectedTitle,
            actual: guess.title,
            coverID: cover.id
        )

        // Author: compare compact alphanumeric strings so initials remain stable (e.g. "B.H." vs "BH").
        assertExpectedAuthor(
            expected: cover.expectedAuthor,
            actual: guess.author,
            coverID: cover.id
        )
    }

    private func recognizeTextLines(from image: UIImage) async throws -> [(text: String, box: CGRect)] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "VisionOCRCoverExtractionIntegrationTests", code: 1)
        }

        let observations: [VNRecognizedTextObservation] = await withCheckedContinuation { cont in
            let request = VNRecognizeTextRequest { request, error in
                if error != nil {
                    cont.resume(returning: [])
                    return
                }
                cont.resume(returning: (request.results as? [VNRecognizedTextObservation]) ?? [])
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.02

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    cont.resume(returning: [])
                }
            }
        }

        return observations.compactMap { obs in
            guard let text = obs.topCandidates(1).first?.string else { return nil }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return (trimmed, obs.boundingBox)
        }
    }

    private func assertExpectedTitle(expected: String, actual: String, coverID: String) {
        let expectedWords = words(from: expected)
        let actualWords = Set(words(from: actual))

        let missing = expectedWords.filter { !actualWords.contains($0) }

        // Strict for very short titles; tolerant for longer titles.
        let allowedMissing = expectedWords.count <= 2 ? 0 : 1
        if missing.count > allowedMissing {
            let message =
                "Missing title words for fixture id=\(coverID).\n" +
                "Expected: \(expected)\n" +
                "Actual:   \(actual)\n" +
                "Missing:  \(missing.joined(separator: ", "))"
            XCTFail(message)
        }
    }

    private func assertExpectedAuthor(expected: String, actual: String, coverID: String) {
        let expectedCompact = compactAlnum(expected)
        let actualCompact = compactAlnum(actual)

        if expectedCompact.isEmpty || actualCompact.isEmpty || !actualCompact.contains(expectedCompact) {
            let message =
                "Author mismatch for fixture id=\(coverID).\n" +
                "Expected: \(expected)\n" +
                "Actual:   \(actual)\n" +
                "ExpectedCompact: \(expectedCompact)\n" +
                "ActualCompact:   \(actualCompact)"
            XCTFail(message)
        }
    }

    private func words(from s: String) -> [String] {
        let lowered = s.lowercased()
        let cleaned = lowered.map { ch -> Character in
            if ch.isLetter || ch.isNumber {
                return ch
            }
            return " "
        }
        return String(cleaned)
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private func compactAlnum(_ s: String) -> String {
        String(s.lowercased().filter { $0.isLetter || $0.isNumber })
    }

    private func debugDump(
        cover: TestFixtures.OCRCoverFixtures.Cover,
        rawLines: [(text: String, box: CGRect)],
        cleanedLines: [(text: String, box: CGRect)],
        guess: (title: String, author: String)
    ) -> String {
        var out: [String] = []
        out.append("Fixture id: \(cover.id)")
        out.append("Expected title: \(cover.expectedTitle)")
        out.append("Expected author: \(cover.expectedAuthor)")
        out.append("Guessed title: \(guess.title)")
        out.append("Guessed author: \(guess.author)")
        out.append("")
        out.append("Raw lines (sorted):")
        for item in rawLines {
            out.append("  - y=\(String(format: "%.3f", item.box.midY)) x=\(String(format: "%.3f", item.box.minX)) : \(item.text)")
        }
        out.append("")
        out.append("Cleaned lines:")
        for item in cleanedLines {
            out.append("  - y=\(String(format: "%.3f", item.box.midY)) x=\(String(format: "%.3f", item.box.minX)) : \(item.text)")
        }
        return out.joined(separator: "\n")
    }
}
