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
        // Configure global UI appearance before any views are created
        Self.configureAppearance()

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

    /// Configure global UI appearance for tab bar and navigation bar
    private static func configureAppearance() {
        // Tab Bar appearance - warm paper background with brand accent
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(red: 1.0, green: 0.984, blue: 0.953, alpha: 1.0) // Warm paper

        // Selected tab - brand color (deep blue #2C3E50)
        let brandColor = UIColor(red: 0.173, green: 0.243, blue: 0.314, alpha: 1.0)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = brandColor
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: brandColor]

        // Normal tab - subtle gray
        let tertiaryColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        tabAppearance.stackedLayoutAppearance.normal.iconColor = tertiaryColor
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: tertiaryColor]

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Navigation Bar appearance - warm paper background
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(red: 0.984, green: 0.969, blue: 0.933, alpha: 1.0) // BackgroundPrimary
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
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
