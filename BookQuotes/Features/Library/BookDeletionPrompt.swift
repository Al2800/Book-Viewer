import Foundation
import SwiftData

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

@MainActor
struct BookDeletionService {
    let modelContext: ModelContext

    func delete(_ book: Book) throws {
        let bookId = book.id
        let sessions = try modelContext.fetch(FetchDescriptor<CaptureSession>())
            .filter { $0.book?.id == bookId }
        let queueItems = try modelContext.fetch(FetchDescriptor<CaptureQueueItem>())
            .filter { $0.book?.id == bookId }

        let imageURLs = sessions.flatMap(\.captures).compactMap(\.imageURL)
            + queueItems.map(\.fullImagePath)

        sessions.forEach(modelContext.delete)
        queueItems.forEach(modelContext.delete)
        modelContext.delete(book)
        try modelContext.save()

        for imageURL in imageURLs {
            try? CaptureImageFileSecurity.removeFileIfPresent(at: imageURL)
        }
    }
}
