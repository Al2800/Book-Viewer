import Foundation
import SwiftData

struct LibraryNavigationLookup {
    let modelContext: ModelContext

    func book(id bookId: UUID) -> Book? {
        let targetId = bookId
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate<Book> { $0.id == targetId }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func quote(id quoteId: UUID) -> Quote? {
        let targetId = quoteId
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate<Quote> { $0.id == targetId }
        )
        return try? modelContext.fetch(descriptor).first
    }
}
