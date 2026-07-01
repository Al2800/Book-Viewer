import Foundation

struct QuoteSaveDraft {
    var extractedQuote: ExtractedQuote
    var book: Book
    var sourceImage: Data?

    func makeQuote() throws -> Quote {
        let quote = Quote(
            text: extractedQuote.text,
            book: book,
            markingType: extractedQuote.markingType
        )

        quote.pageNumber = extractedQuote.pageNumber
        quote.chapter = extractedQuote.chapter
        quote.marginNote = extractedQuote.marginNote
        quote.confidence = extractedQuote.confidence
        quote.sourceImageData = sourceImage
        quote.customMarkingDefinition = extractedQuote.customMarkingDefinition

        try quote.validate()
        return quote
    }
}
