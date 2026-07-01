import Foundation

enum CaptureQueueNetworkTransition {
    static func shouldStartProcessing(
        wasConnected: Bool,
        isConnected: Bool,
        isAutoProcessEnabled: Bool
    ) -> Bool {
        !wasConnected && isConnected && isAutoProcessEnabled
    }
}
