import Foundation
import Network

// MARK: - NetworkMonitor

/// Monitors network connectivity using NWPathMonitor.
/// Provides real-time updates when network status changes.
/// Used by the capture queue to determine when to process pending items.
@MainActor
@Observable
final class NetworkMonitor {

    // MARK: - Connection Type

    /// Type of network connection currently available.
    enum ConnectionType: String, Sendable {
        case wifi
        case cellular
        case wired
        case unknown

        /// Human-readable description of the connection type.
        var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .wired: return "Ethernet"
            case .unknown: return "Unknown"
            }
        }

        /// SF Symbol for the connection type.
        var systemImage: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .wired: return "cable.connector"
            case .unknown: return "network.slash"
            }
        }
    }

    // MARK: - Properties

    /// Whether the device is currently connected to a network.
    private(set) var isConnected: Bool = false

    /// The type of network connection (WiFi, Cellular, etc.).
    private(set) var connectionType: ConnectionType = .unknown

    /// Whether the connection is expensive (e.g., cellular with data cap).
    private(set) var isExpensive: Bool = false

    /// Whether the connection is constrained (e.g., Low Data Mode enabled).
    private(set) var isConstrained: Bool = false

    /// The underlying NWPathMonitor instance.
    private let monitor: NWPathMonitor

    /// Dedicated queue for network monitoring.
    private let queue = DispatchQueue(label: "com.bookquotes.NetworkMonitor", qos: .utility)

    /// Whether the monitor is currently running.
    private var isMonitoring: Bool = false

    // MARK: - Initialization

    init() {
        self.monitor = NWPathMonitor()
    }

    /// Initialize with a specific interface type requirement.
    /// - Parameter requiredInterfaceType: Only monitor this interface type.
    init(requiredInterfaceType: NWInterface.InterfaceType) {
        self.monitor = NWPathMonitor(requiredInterfaceType: requiredInterfaceType)
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// Start monitoring network changes.
    /// Call this when the app becomes active or when you need connectivity info.
    func startMonitoring() {
        guard !isMonitoring else { return }

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.updateStatus(from: path)
            }
        }

        monitor.start(queue: queue)
        isMonitoring = true
    }

    /// Stop monitoring network changes.
    /// Call this when the app enters background or monitoring is no longer needed.
    func stopMonitoring() {
        guard isMonitoring else { return }

        monitor.cancel()
        isMonitoring = false
    }

    /// Manually refresh the current network status.
    /// Useful after app returns from background.
    func refresh() {
        // The monitor will automatically provide the latest status
        // when started, so we can just restart it
        stopMonitoring()
        startMonitoring()
    }

    // MARK: - Private Methods

    /// Update all status properties from the current path.
    private func updateStatus(from path: NWPath) {
        isConnected = path.status == .satisfied
        connectionType = getConnectionType(from: path)
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
    }

    /// Determine the connection type from an NWPath.
    private func getConnectionType(from path: NWPath) -> ConnectionType {
        guard path.status == .satisfied else {
            return .unknown
        }

        // Check interface types in priority order
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        } else {
            return .unknown
        }
    }
}

// MARK: - Convenience Extensions

extension NetworkMonitor {
    /// Whether the connection is suitable for large transfers (non-expensive and not constrained).
    var isSuitableForLargeTransfers: Bool {
        isConnected && !isExpensive && !isConstrained
    }

    /// Whether the connection is WiFi.
    var isOnWiFi: Bool {
        isConnected && connectionType == .wifi
    }

    /// Whether the connection is cellular.
    var isOnCellular: Bool {
        isConnected && connectionType == .cellular
    }

    /// Human-readable status description.
    var statusDescription: String {
        if isConnected {
            var parts = [connectionType.displayName]
            if isExpensive {
                parts.append("(metered)")
            }
            if isConstrained {
                parts.append("(Low Data Mode)")
            }
            return parts.joined(separator: " ")
        } else {
            return "No connection"
        }
    }
}

// MARK: - Shared Instance

extension NetworkMonitor {
    /// Shared instance for app-wide network monitoring.
    /// Start monitoring in your App's init or scene phase handler.
    nonisolated(unsafe) static let shared = NetworkMonitor()
}
