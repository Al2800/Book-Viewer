import XCTest
import SwiftData

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

