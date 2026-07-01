import Foundation

@MainActor
protocol CaptureQueueNetworkMonitoring: AnyObject {
    var isConnected: Bool { get }

    func startMonitoring()
}

extension NetworkMonitor: CaptureQueueNetworkMonitoring {}
