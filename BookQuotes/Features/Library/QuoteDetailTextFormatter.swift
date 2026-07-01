import Foundation

enum QuoteDetailTextFormatter {
    static func shareText(for quote: Quote) -> String {
        var text = "\"\(quote.text)\""

        if let book = quote.book {
            text += "\n\n— \(book.title) by \(book.author)"
            if let page = quote.pageNumber {
                text += ", p. \(page)"
            }
        }

        return text
    }
}
