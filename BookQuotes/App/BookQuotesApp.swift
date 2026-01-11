import SwiftUI
import SwiftData

@main
@MainActor
struct BookQuotesApp: App {
    let container: ModelContainer?
    let containerError: Error?

    /// Shared services initialized at app launch
    @State private var authService: AuthService
    @State private var geminiService: GeminiService
    @State private var networkMonitor: NetworkMonitor

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

        // Initialize services
        let auth = AuthService()
        let gemini = GeminiService(authService: auth)

        _authService = State(initialValue: auth)
        _geminiService = State(initialValue: gemini)
        _networkMonitor = State(initialValue: NetworkMonitor.shared)

        let containerResult: ModelContainer?
        let errorResult: Error?
        do {
            containerResult = try ModelContainer(for: schema, configurations: [config])
            errorResult = nil
        } catch {
            containerResult = nil
            errorResult = error
        }

        container = containerResult
        containerError = errorResult

        // Initialize the shared queue manager
        if let containerResult {
            CaptureQueueManager.initialize(
                modelContainer: containerResult,
                geminiService: gemini,
                networkMonitor: NetworkMonitor.shared
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
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
                    .modelContainer(container)
            } else {
                ErrorView(
                    error: containerError ?? NSError(
                        domain: "com.bookquotes",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to initialize local storage."]
                    ),
                    style: .critical
                )
            }
        }
    }
}

// MARK: - Preview Support

extension ModelContainer {
    /// In-memory container for SwiftUI previews
    @MainActor
    static var preview: ModelContainer? {
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

        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            return nil
        }

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
    }
}
