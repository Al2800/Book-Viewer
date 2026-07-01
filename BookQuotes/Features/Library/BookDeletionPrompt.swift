struct BookDeletionPrompt: Equatable {
    let bookTitle: String
    let quoteCount: Int

    var title: String {
        "Delete \"\(bookTitle)\"?"
    }

    var destructiveButtonTitle: String {
        "Delete Book and All Quotes"
    }

    var message: String {
        "This will permanently delete the book and all \(quoteCount) \(quoteLabel). This cannot be undone."
    }

    private var quoteLabel: String {
        quoteCount == 1 ? "quote" : "quotes"
    }
}
