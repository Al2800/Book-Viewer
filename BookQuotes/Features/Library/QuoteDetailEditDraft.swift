import Foundation

struct QuoteDetailEditDraft {
    var text: String
    var marginNote: String
    var pageNumberText: String
    var modifiedDate: Date = Date()

    func apply(to quote: Quote) {
        quote.text = text
        quote.marginNote = marginNote.isEmpty ? nil : marginNote
        quote.pageNumber = Int(pageNumberText)
        quote.dateModified = modifiedDate
    }
}
