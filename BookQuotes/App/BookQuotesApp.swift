import SwiftUI
import SwiftData

@main
struct BookQuotesApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Book.self,
            Quote.self,
            Collection.self,
            Tag.self,
            MarkingDefinition.self,
            CaptureSession.self,
            PageCapture.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

// MARK: - Preview Support

extension ModelContainer {
    /// In-memory container for SwiftUI previews
    @MainActor
    static var preview: ModelContainer {
        let schema = Schema([
            Book.self,
            Quote.self,
            Collection.self,
            Tag.self,
            MarkingDefinition.self,
            CaptureSession.self,
            PageCapture.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [config])

            // Add sample data for previews
            let context = container.mainContext

            let sampleBook = Book(
                title: "Meditations",
                author: "Marcus Aurelius"
            )
            sampleBook.status = .currentlyReading
            context.insert(sampleBook)

            let sampleQuote = Quote(
                text: "You have power over your mind - not outside events. Realize this, and you will find strength.",
                book: sampleBook
            )
            sampleQuote.pageNumber = 42
            context.insert(sampleQuote)

            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
