import SwiftUI
import SwiftData

@main
struct BookQuotesApp: App {
    let container: ModelContainer

    /// Shared services initialized at app launch
    @State private var authService: AuthService
    @State private var geminiService: GeminiService
    @State private var networkMonitor = NetworkMonitor.shared

    init() {
        let schema = Schema([
            Book.self,
            Quote.self,
            Collection.self,
            Tag.self,
            MarkingDefinition.self,
            CaptureSession.self,
            PageCapture.self,
            CaptureQueueItem.self
        ])

        // Use in-memory storage for UI tests to avoid mutating real user data
        let isUITesting = UITestConfiguration.isUITesting
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITesting,
            cloudKitDatabase: isUITesting ? .none : .automatic
        )

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Initialize services
        let auth = AuthService()
        let gemini = GeminiService(authService: auth)

        _authService = State(initialValue: auth)
        _geminiService = State(initialValue: gemini)

        // Initialize the shared queue manager
        CaptureQueueManager.initialize(
            modelContainer: container,
            geminiService: gemini
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .environment(geminiService)
                .environment(networkMonitor)
                .task {
                    // Seed test data for UI tests (if applicable)
                    if UITestConfiguration.isUITesting {
                        let seeder = UITestDataSeeder(modelContext: container.mainContext)
                        try? await seeder.seedTestDataIfNeeded()

                        // Rebuild search index for seeded data
                        if let searchService = try? SearchService() {
                            await seeder.rebuildSearchIndexIfNeeded(searchService: searchService)
                        }
                    }

                    // Start network monitoring
                    networkMonitor.startMonitoring()

                    // Start queue processing
                    if let queueManager = CaptureQueueManager.shared {
                        await queueManager.start()
                    }
                }
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
            PageCapture.self,
            CaptureQueueItem.self
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
