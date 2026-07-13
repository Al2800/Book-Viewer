import SwiftData

extension CaptureQueueManager {
    /// Shared instance for app-wide queue management.
    /// Initialize in your App's init with the appropriate dependencies.
    @MainActor
    static var shared: CaptureQueueManager?

    /// Initialize the shared instance.
    /// Uses the same model-assisted extractor seam as interactive quote review.
    @MainActor
    static func initialize(
        modelContainer: ModelContainer,
        authService: AuthService,
        networkMonitor: any CaptureQueueNetworkMonitoring
    ) {
        shared = CaptureQueueManager(
            modelContainer: modelContainer,
            quoteExtractor: QuoteExtractionPipeline.live(authService: authService),
            networkMonitor: networkMonitor
        )
    }
}
