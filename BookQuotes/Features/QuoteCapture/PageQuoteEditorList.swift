import Foundation

struct PageQuoteEditorList: Equatable {
    private(set) var quotes: [EditableQuote]

    var countTitle: String {
        "\(quotes.count) Quote\(quotes.count == 1 ? "" : "s")"
    }

    var isEmpty: Bool {
        quotes.isEmpty
    }

    mutating func delete(_ quote: EditableQuote) {
        quotes.removeAll { $0.id == quote.id }
    }
}
