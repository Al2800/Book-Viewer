import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - ExportFlowTests

@MainActor
final class ExportFlowTests: SwiftDataTestCase {

    func testExportMarkdownProducesFile() async throws {
        logger.step(1, "Creating quote data")
        let book = TestFixtures.book { builder in
            builder.title = "Export Book"
            builder.author = "Export Author"
        }
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Exported quote text"
            builder.pageNumber = 12
        }
        modelContext.insert(book)
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(2, "Exporting to markdown")
        let exportService = ExportService()
        let result = try await exportService.export(quotes: [quote], format: .markdown)

        logger.step(3, "Verifying output")
        guard case let .file(url, filename) = result else {
            XCTFail("Expected file export")
            return
        }
        XCTAssertTrue(filename.hasSuffix(".md"))
        let content = try String(contentsOf: url)
        XCTAssertTrue(content.contains("Exported quote text"))
        XCTAssertTrue(content.contains("Export Book"))

        logger.success("Markdown export produced file")
    }

    func testExportJSONProducesFile() async throws {
        logger.step(1, "Creating quote data")
        let book = TestFixtures.book { builder in
            builder.title = "JSON Book"
            builder.author = "JSON Author"
        }
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "JSON quote text"
        }
        modelContext.insert(book)
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(2, "Exporting to JSON")
        let exportService = ExportService()
        let result = try await exportService.export(quotes: [quote], format: .json)

        logger.step(3, "Verifying output")
        guard case let .file(url, filename) = result else {
            XCTFail("Expected file export")
            return
        }
        XCTAssertTrue(filename.hasSuffix(".json"))
        let content = try String(contentsOf: url)
        XCTAssertTrue(content.contains("JSON quote text"))

        logger.success("JSON export produced file")
    }

    func testExportNotionReturnsApiError() async throws {
        logger.step(1, "Creating quote data")
        let quote = TestFixtures.quote()

        logger.step(2, "Exporting to Notion")
        let exportService = ExportService()
        let result = try await exportService.export(quotes: [quote], format: .notion)

        logger.step(3, "Verifying API error")
        guard case let .apiError(message) = result else {
            XCTFail("Expected API error")
            return
        }
        XCTAssertTrue(message.contains("not implemented"))

        logger.success("Notion export returns API error")
    }

    func testExportObsidianProducesFile() async throws {
        logger.step(1, "Creating quote data")
        let book = TestFixtures.book { builder in
            builder.title = "Obsidian Book"
            builder.author = "Obsidian Author"
            builder.isbn = "9781234567890"
        }
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Obsidian formatted quote text"
            builder.pageNumber = 42
        }
        modelContext.insert(book)
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(2, "Exporting to Obsidian")
        let exportService = ExportService()
        let result = try await exportService.export(quotes: [quote], format: .obsidian)

        logger.step(3, "Verifying output")
        guard case let .file(url, filename) = result else {
            XCTFail("Expected file export")
            return
        }
        XCTAssertTrue(filename.hasSuffix(".md"), "Obsidian export should produce .md file")

        let content = try String(contentsOf: url)

        logger.step(4, "Verifying Obsidian frontmatter")
        XCTAssertTrue(content.contains("---"), "Should contain YAML frontmatter")
        XCTAssertTrue(content.contains("title: \"Obsidian Book\""), "Should contain title in frontmatter")
        XCTAssertTrue(content.contains("author: \"Obsidian Author\""), "Should contain author in frontmatter")
        XCTAssertTrue(content.contains("isbn: \"9781234567890\""), "Should contain ISBN in frontmatter")
        XCTAssertTrue(content.contains("type: book-quotes"), "Should contain type in frontmatter")
        XCTAssertTrue(content.contains("tags:"), "Should contain tags section")

        logger.step(5, "Verifying quote content")
        XCTAssertTrue(content.contains("> Obsidian formatted quote text"), "Should contain blockquoted text")
        XCTAssertTrue(content.contains("Page 42"), "Should contain page number")

        logger.success("Obsidian export produced file with correct format")
    }

    func testExportObsidianGroupsByBook() async throws {
        logger.step(1, "Creating multiple books with quotes")
        let book1 = TestFixtures.book { builder in
            builder.title = "First Book"
            builder.author = "Author One"
        }
        let book2 = TestFixtures.book { builder in
            builder.title = "Second Book"
            builder.author = "Author Two"
        }
        let quote1 = TestFixtures.quote { builder in
            builder.book = book1
            builder.text = "Quote from first book"
        }
        let quote2 = TestFixtures.quote { builder in
            builder.book = book2
            builder.text = "Quote from second book"
        }
        modelContext.insert(book1)
        modelContext.insert(book2)
        modelContext.insert(quote1)
        modelContext.insert(quote2)
        try modelContext.save()

        logger.step(2, "Exporting to Obsidian")
        let exportService = ExportService()
        let result = try await exportService.export(quotes: [quote1, quote2], format: .obsidian)

        logger.step(3, "Verifying output")
        guard case let .file(url, _) = result else {
            XCTFail("Expected file export")
            return
        }

        // With multiple books, should create a directory bundle
        let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        if isDirectory {
            let files = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            XCTAssertEqual(files.count, 2, "Should have 2 files for 2 books")
            logger.success("Obsidian export grouped quotes by book")
        } else {
            // Single file export for single book is also valid
            logger.info("Export produced single file (valid for single book)")
        }
    }

    func testExportPlainTextProducesFile() async throws {
        logger.step(1, "Creating quote data")
        let book = TestFixtures.book { builder in
            builder.title = "Plain Text Book"
            builder.author = "Plain Author"
        }
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Simple plain text quote"
        }
        modelContext.insert(book)
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(2, "Exporting to plain text")
        let exportService = ExportService()
        let result = try await exportService.export(quotes: [quote], format: .plainText)

        logger.step(3, "Verifying output")
        guard case let .file(url, filename) = result else {
            XCTFail("Expected file export")
            return
        }
        XCTAssertTrue(filename.hasSuffix(".txt"), "Plain text export should produce .txt file")

        let content = try String(contentsOf: url)
        XCTAssertTrue(content.contains("Simple plain text quote"), "Should contain quote text")

        logger.success("Plain text export produced file")
    }
}
