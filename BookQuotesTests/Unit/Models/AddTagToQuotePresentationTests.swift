import XCTest

@testable import BookQuotes

final class AddTagToQuotePresentationTests: XCTestCase {
    func testAvailableTagsExcludesCurrentTagsAndPreservesAllTagsOrder() {
        let strategy = Tag(name: "strategy")
        let craft = Tag(name: "craft")
        let systems = Tag(name: "systems")

        let presentation = AddTagToQuotePresentation(
            allTags: [strategy, craft, systems],
            currentTags: [craft]
        )

        XCTAssertEqual(presentation.availableTags.map(\.id), [strategy.id, systems.id])
    }

    func testAvailableTagsReturnsAllTagsWhenQuoteHasNoCurrentTags() {
        let strategy = Tag(name: "strategy")
        let craft = Tag(name: "craft")

        let presentation = AddTagToQuotePresentation(
            allTags: [strategy, craft],
            currentTags: []
        )

        XCTAssertEqual(presentation.availableTags.map(\.id), [strategy.id, craft.id])
    }
}
