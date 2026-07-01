import SwiftData

extension CaptureQueueManager {
    /// Shared instance for app-wide queue management.
    /// Initialize in your App's init with the appropriate dependencies.
    @MainActor
    static var shared: CaptureQueueManager?

    /// Initialize the shared instance.
    /// Call this early in app lifecycle.
    @MainActor
    static func initialize(
        modelContainer: ModelContainer,
        geminiService: GeminiService,
        networkMonitor: any CaptureQueueNetworkMonitoring
    ) {
        shared = CaptureQueueManager(
            modelContainer: modelContainer,
            geminiService: geminiService,
            networkMonitor: networkMonitor
        )
    }
}
