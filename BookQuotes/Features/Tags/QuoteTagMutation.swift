import Foundation

struct QuoteTagMutation {
    var modifiedDate: Date = Date()

    func add(_ tag: Tag, to quote: Quote) {
        quote.tags.append(tag)
        tag.quotes.append(quote)
        quote.dateModified = modifiedDate
    }

    func remove(_ tag: Tag, from quote: Quote) {
        if let index = quote.tags.firstIndex(where: { $0.id == tag.id }) {
            quote.tags.remove(at: index)
        }
        if let index = tag.quotes.firstIndex(where: { $0.id == quote.id }) {
            tag.quotes.remove(at: index)
        }
        quote.dateModified = modifiedDate
    }
}
