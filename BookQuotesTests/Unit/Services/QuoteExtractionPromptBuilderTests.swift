import XCTest

@testable import BookQuotes

// MARK: - QuoteExtractionPromptBuilderTests

final class QuoteExtractionPromptBuilderTests: XCTestCase {

    func testBuildPromptUsesDefaultsWhenNoMarkings() {
        let prompt = QuoteExtractionPromptBuilder.buildPrompt(markings: [])
        XCTAssertTrue(prompt.contains("Underline"))
        XCTAssertTrue(prompt.contains("\"underline\""))
        XCTAssertTrue(prompt.contains("\"highlight\""))
    }

    func testBuildPromptUsesEnabledMarkingsOnly() {
        let enabled = MarkingDefinition(
            name: "Double Underline",
            visualDescription: "Two lines",
            meaning: "Critical"
        )
        let disabled = MarkingDefinition(
            name: "Bracket",
            visualDescription: "Brackets",
            meaning: "Section"
        )
        disabled.isEnabled = false

        let prompt = QuoteExtractionPromptBuilder.buildPrompt(markings: [enabled, disabled])
        XCTAssertTrue(prompt.contains("Double Underline"))
        XCTAssertFalse(prompt.contains("Brackets"))
        XCTAssertTrue(prompt.contains("\"double_underline\""))
    }

    func testBuildQuickPromptIncludesMarkingNames() {
        let marking = MarkingDefinition(
            name: "Margin Note",
            visualDescription: "Margin notes",
            meaning: "Thoughts"
        )

        let prompt = QuoteExtractionPromptBuilder.buildQuickPrompt(markings: [marking])
        XCTAssertTrue(prompt.contains("Margin Note"))
    }
}
