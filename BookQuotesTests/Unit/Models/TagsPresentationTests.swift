import XCTest

@testable import BookQuotes

final class TagsPresentationTests: XCTestCase {
    func testTotalUsesCountsQuotesAcrossTags() {
        let strategy = tag(name: "strategy", quoteCount: 2)
        let craft = tag(name: "craft", quoteCount: 1)

        let presentation = TagsPresentation(tags: [strategy, craft])

        XCTAssertEqual(presentation.totalUses, 3)
    }

    func testFilteringReturnsAllTagsWhenSearchTextIsEmpty() {
        let tags = [
            tag(name: "strategy", quoteCount: 0),
            tag(name: "craft", quoteCount: 0)
        ]

        let presentation = TagsPresentation(tags: tags)

        XCTAssertEqual(presentation.filteredTags(searchText: "").map(\.name), ["strategy", "craft"])
    }

    func testFilteringMatchesCaseInsensitively() {
        let tags = [
            tag(name: "Strategy", quoteCount: 0),
            tag(name: "craft", quoteCount: 0),
            tag(name: "Systems", quoteCount: 0)
        ]

        let presentation = TagsPresentation(tags: tags)

        XCTAssertEqual(presentation.filteredTags(searchText: "ST").map(\.name), ["strategy", "systems"])
    }

    private func tag(name: String, quoteCount: Int) -> Tag {
        let tag = Tag(name: name)
        tag.quotes = (0..<quoteCount).map { index in
            Quote(text: "\(name) quote \(index)")
        }
        return tag
    }
}
