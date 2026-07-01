struct QuoteDetailEditFields: Equatable {
    let text: String
    let marginNote: String
    let pageNumberText: String

    init(quote: Quote) {
        self.text = quote.text
        self.marginNote = quote.marginNote ?? ""
        self.pageNumberText = quote.pageNumber.map(String.init) ?? ""
    }
}
