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

    func testBuildPromptRequestsBestEffortMarkedTextWhenBoundariesAreUncertain() {
        let prompt = QuoteExtractionPromptBuilder.buildPrompt(markingPrompts: [])
            .lowercased()

        XCTAssertTrue(prompt.contains("best-effort"))
        XCTAssertTrue(prompt.contains("lower confidence"))
        XCTAssertTrue(prompt.contains("do not return an empty quotes array"))
    }

    func testBuildPromptTreatsBracketedParagraphsAsCompleteMarkedPassages() {
        let prompt = QuoteExtractionPromptBuilder.buildPrompt(markingPrompts: [])
            .lowercased()

        XCTAssertTrue(prompt.contains("bracketed or side-lined paragraph"))
        XCTAssertTrue(prompt.contains("every readable line"))
        XCTAssertTrue(prompt.contains("do not limit extraction to the underlined sentence"))
    }

    func testBuildPromptTreatsSmallBracketsAndTicksAsIntentionalMarks() {
        let prompt = QuoteExtractionPromptBuilder.buildPrompt(markingPrompts: [])
            .lowercased()

        XCTAssertTrue(prompt.contains("small brackets"))
        XCTAssertTrue(prompt.contains("short side ticks"))
        XCTAssertTrue(prompt.contains("partial bracket hooks"))
        XCTAssertTrue(prompt.contains("even if the region is only a short phrase or one line"))
    }

    func testBuildPromptRequestsLineWrapHyphenationRepairWithoutInventingText() {
        let prompt = QuoteExtractionPromptBuilder.buildPrompt(markingPrompts: [])
            .lowercased()

        XCTAssertTrue(prompt.contains("line-wrap hyphenation"))
        XCTAssertTrue(prompt.contains("preserve hard hyphens"))
        XCTAssertTrue(prompt.contains("do not invent missing text"))
    }

    func testBuildCoverExtractionPromptRejectsPraiseAndMarketingCopyAsMetadata() {
        let prompt = QuoteExtractionPromptBuilder.buildCoverExtractionPrompt()
            .lowercased()

        XCTAssertTrue(prompt.contains("praise quotes"))
        XCTAssertTrue(prompt.contains("bestseller"))
        XCTAssertTrue(prompt.contains("marketing blurbs"))
        XCTAssertTrue(prompt.contains("do not include"))
    }
}
