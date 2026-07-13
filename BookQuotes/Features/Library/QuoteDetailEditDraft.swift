import Foundation
import SwiftData

struct QuoteDetailEditDraft {
    var text: String
    var marginNote: String
    var pageNumberText: String
    var modifiedDate: Date = Date()

    /// Applies edits and records correction feedback for changed fields.
    func apply(to quote: Quote, in context: ModelContext) {
        let originalText = quote.text
        let originalMarginNote = quote.marginNote ?? ""
        let originalPageNumber = quote.pageNumber

        let nextMarginNote = marginNote.isEmpty ? nil : marginNote
        let nextPageNumber = Int(pageNumberText)

        if text != originalText {
            quote.recordTextCorrection(
                original: originalText,
                corrected: text,
                context: context
            )
        }

        if (nextMarginNote ?? "") != originalMarginNote {
            quote.recordMarginNoteCorrection(
                originalNote: originalMarginNote,
                correctedNote: nextMarginNote ?? "",
                context: context
            )
        }

        if nextPageNumber != originalPageNumber {
            quote.recordPageCorrection(
                originalPage: originalPageNumber,
                correctedPage: nextPageNumber,
                context: context
            )
        }

        quote.text = text
        quote.marginNote = nextMarginNote
        quote.pageNumber = nextPageNumber
        quote.dateModified = modifiedDate
    }
}
