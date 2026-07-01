import Foundation

enum BookDetailQuoteSortOrder: String, CaseIterable {
    case dateAdded = "Date Added"
    case pageNumber = "Page Number"
    case markingType = "Marking Type"
    case favorite = "Favorites First"
}

struct BookDetailQuotePresentation {
    let quotes: [Quote]

    var uniquePageCount: Int {
        Set(quotes.compactMap(\.pageNumber)).count
    }

    var markingTypes: [MarkingType] {
        Array(Set(quotes.map(\.markingType))).sorted { $0.rawValue < $1.rawValue }
    }

    func visibleQuotes(
        filter: MarkingType?,
        sortOrder: BookDetailQuoteSortOrder
    ) -> [Quote] {
        var visibleQuotes = quotes

        if let filter {
            visibleQuotes = visibleQuotes.filter { $0.markingType == filter }
        }

        switch sortOrder {
        case .dateAdded:
            visibleQuotes.sort { $0.captureDate > $1.captureDate }
        case .pageNumber:
            visibleQuotes.sort { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }
        case .markingType:
            visibleQuotes.sort { $0.markingType.rawValue < $1.markingType.rawValue }
        case .favorite:
            visibleQuotes.sort { ($0.isFavorite ? 0 : 1) < ($1.isFavorite ? 0 : 1) }
        }

        return visibleQuotes
    }
}
