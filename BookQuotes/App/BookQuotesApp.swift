import SwiftUI
import SwiftData
import os

@main
@MainActor
struct BookQuotesApp: App {
    let container: ModelContainer?
    let containerError: Error?

    private static let persistenceLocalStoreNameKey = "persistence_local_store_name"
    private static let persistenceRecoveryMessageKey = "persistence_recovery_message"

    /// Shared services initialized at app launch
    @State private var authService: AuthService
    @State private var geminiService: GeminiService
    @State private var networkMonitor: NetworkMonitor

    init() {
        // Configure global UI appearance before any views are created
        Self.configureAppearance()

        let logger = Logger(subsystem: "com.acampbell.bookquotes", category: "persistence")

        let schema = Schema([
            Book.self,
            Quote.self,
            QuoteCorrection.self,
            Collection.self,
            Tag.self,
            MarkingDefinition.self,
            CaptureSession.self,
            PageCapture.self,
            CaptureQueueItem.self
        ])

        func setRecoveryMessage(_ message: String) {
            UserDefaults.standard.set(message, forKey: Self.persistenceRecoveryMessageKey)
        }

        func localStoreName() -> String {
            UserDefaults.standard.string(forKey: Self.persistenceLocalStoreNameKey) ?? "BookQuotesLocal"
        }

        func rotateLocalStoreName() -> String {
            let name = "BookQuotesLocal-\(UUID().uuidString)"
            UserDefaults.standard.set(name, forKey: Self.persistenceLocalStoreNameKey)
            return name
        }

        // Use in-memory storage for UI tests to avoid mutating real user data
        let isUITesting = UITestConfiguration.isUITesting
        if isUITesting {
            if UITestConfiguration.shouldResetAuthentication {
                KeychainService.shared.clearAllCredentials()
            }
            if UITestConfiguration.shouldResetOnboarding {
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                AIProcessingConsentStore.shared.revoke()
            } else {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
            UserDefaults.standard.set(false, forKey: "uiTestSeeded")
        }

        // v0.x shipping default: local-only SwiftData.
        //
        // CloudKit-backed SwiftData is extremely sensitive to entitlements/capabilities and can fail
        // in ways that prevent the app from booting (often surfacing as SwiftDataError(1)).
        // We can re-introduce CloudKit behind a user-facing toggle once the app is stable in the wild.
        let primaryLocalName = localStoreName()
        let config = ModelConfiguration(
            primaryLocalName,
            schema: schema,
            isStoredInMemoryOnly: isUITesting,
            cloudKitDatabase: .none
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
            let nsError = error as NSError
            logger.error("SwiftData container init failed (local-only): domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public) desc=\(nsError.localizedDescription, privacy: .public)")

            if !isUITesting {
                func makeLocalOnlyConfig(name: String) -> ModelConfiguration {
                    ModelConfiguration(
                        name,
                        schema: schema,
                        isStoredInMemoryOnly: false,
                        cloudKitDatabase: .none
                    )
                }

                do {
                    // If the local store itself is corrupted/misconfigured, rotate to a fresh store
                    // without deleting the old one (safe recovery for early versions).
                    let rotatedName = rotateLocalStoreName()
                    do {
                        containerResult = try ModelContainer(
                            for: schema,
                            configurations: [makeLocalOnlyConfig(name: rotatedName)]
                        )
                        errorResult = nil
                        logger.warning("SwiftData initialized using rotated local store after local init failure.")
                        setRecoveryMessage("Storage was reset due to a startup issue. Your previous local store was preserved; a fresh local store is now in use.")
                    } catch {
                        // Last resort: allow app to boot in-memory so user can still access the UI.
                        let rescueNSError = error as NSError
                        logger.error("SwiftData rescue init failed (in-memory): domain=\(rescueNSError.domain, privacy: .public) code=\(rescueNSError.code, privacy: .public) desc=\(rescueNSError.localizedDescription, privacy: .public)")

                        let rescueConfig = ModelConfiguration(
                            schema: schema,
                            isStoredInMemoryOnly: true,
                            cloudKitDatabase: .none
                        )

                        if let rescueContainer = try? ModelContainer(for: schema, configurations: [rescueConfig]) {
                            containerResult = rescueContainer
                            errorResult = error
                            logger.warning("SwiftData running in rescue in-memory mode; data will not persist.")
                            setRecoveryMessage("Storage could not be opened. Running in temporary mode; data will not persist. Please reinstall the app or contact support if this repeats.")
                        } else {
                            containerResult = nil
                            errorResult = error
                        }
                    }
                } catch {
                    containerResult = nil
                    errorResult = error
                }
            } else {
                containerResult = nil
                errorResult = error
            }
        }

        container = containerResult
        containerError = errorResult

        // Initialize the shared queue manager
        if let containerResult {
            CaptureQueueManager.initialize(
                modelContainer: containerResult,
                authService: auth,
                networkMonitor: NetworkMonitor.shared
            )
        }
    }

    /// Configure global UI appearance for tab bar and navigation bar
    private static func configureAppearance() {
        // Dynamic colors for light/dark consistency
        let lightBackground = UIColor(red: 0.984, green: 0.969, blue: 0.933, alpha: 1.0)
        let darkBackground = UIColor(red: 0.140, green: 0.120, blue: 0.100, alpha: 1.0)
        let backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? darkBackground : lightBackground
        }

        let lightText = UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0)
        let darkText = UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.0)
        let titleColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? darkText : lightText
        }

        let tertiaryText = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1.0)
                : UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1.0)
        }

        // Tab Bar appearance - warm paper background with brand accent
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = backgroundColor

        // Selected tab - brand color (deep blue #2C3E50)
        let brandColor = UIColor(red: 0.173, green: 0.243, blue: 0.314, alpha: 1.0)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = brandColor
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: brandColor]

        // Normal tab - subtle gray
        tabAppearance.stackedLayoutAppearance.normal.iconColor = tertiaryText
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: tertiaryText]

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Navigation Bar appearance - warm paper background with serif titles
        // for the book-style aesthetic.
        func serifFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
            return UIFont(descriptor: descriptor, size: size)
        }

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = backgroundColor
        navAppearance.titleTextAttributes = [
            .foregroundColor: titleColor,
            .font: serifFont(size: 17, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: titleColor,
            .font: serifFont(size: 34, weight: .semibold)
        ]

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

enum AppReleaseConfiguration {
    /// v1 ships with local-only persistence until CloudKit has been validated in production.
    static let cloudSyncEnabled = false

    /// v1 ships with StoreKit-managed subscriptions and a 7-day introductory trial.
    static let subscriptionsEnabled = true

    static let legalLastUpdated = "March 2026"
    static let supportEmail = "acampbell193@googlemail.com"
}

// MARK: - Preview Support

extension ModelContainer {
    /// In-memory container for SwiftUI previews
    @MainActor
    static var preview: ModelContainer? {
        let schema = Schema([
            Book.self,
            Quote.self,
            QuoteCorrection.self,
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
