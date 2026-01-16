import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - MarkingDefinitionTests

@MainActor
final class MarkingDefinitionTests: SwiftDataTestCase {

    func testSeededDefaultsExist() throws {
        logger.step(1, "Fetching seeded defaults")
        let definitions = try fetchAllMarkingDefinitions()

        logger.step(2, "Validating defaults")
        XCTAssertEqual(definitions.count, MarkingDefinition.systemDefaults.count)
        XCTAssertTrue(definitions.allSatisfy { $0.isSystemDefault })
        XCTAssertTrue(definitions.allSatisfy { $0.sortOrder >= 0 })

        logger.success("System defaults seeded")
    }

    func testCustomDefinitionDefaults() throws {
        logger.step(1, "Creating custom definition")
        let definition = MarkingDefinition(
            name: "Underline",
            visualDescription: "Single line",
            meaning: "Important"
        )
        modelContext.insert(definition)
        try modelContext.save()

        logger.step(2, "Verifying default flags")
        XCTAssertFalse(definition.isSystemDefault)
        XCTAssertTrue(definition.isEnabled)
        XCTAssertEqual(definition.sortOrder, 0)

        logger.success("Custom definition defaults are correct")
    }
}
