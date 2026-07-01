import AVFoundation
import UIKit

// MARK: - Camera Permission Service

/// Manages camera permission state and requests.
/// Handles the critical UX flow for camera access authorization.
@MainActor
@Observable
final class CameraPermissionService {
    // MARK: - Permission Status

    /// Current camera permission status
    private(set) var status: PermissionStatus = .notDetermined

    // MARK: - Status Check

    /// Check current authorization status without prompting
    func checkStatus() {
        if UITestConfiguration.shouldMockCamera {
            status = .authorized
            return
        }
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        status = CameraAuthorizationPolicy.permissionStatus(for: authorizationStatus)
    }

    // MARK: - Permission Request

    /// Request camera permission from the user
    /// - Returns: Whether permission was granted
    @discardableResult
    func requestPermission() async -> Bool {
        if UITestConfiguration.shouldMockCamera {
            status = .authorized
            return true
        }
        // Check if already determined
        checkStatus()
        guard status == .notDetermined else {
            return status == .authorized
        }

        // Request permission
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        status = granted ? .authorized : .denied
        return granted
    }

    // MARK: - Settings Navigation

    /// Open the app's settings page where user can enable camera access
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Convenience Properties

    /// Whether camera access is authorized
    var isAuthorized: Bool {
        status == .authorized
    }

    /// Whether we can request permission (not yet determined)
    var canRequest: Bool {
        status == .notDetermined
    }

    /// Whether the user needs to go to Settings to enable
    var needsSettingsRedirect: Bool {
        status == .denied
    }

    /// Whether access is restricted by system (parental controls, MDM)
    var isRestricted: Bool {
        status == .restricted
    }
}

// MARK: - Permission Status Enum

extension CameraPermissionService {
    /// Camera permission states
    enum PermissionStatus: String, Sendable {
        /// Permission has not been requested yet
        case notDetermined

        /// Camera access is authorized
        case authorized

        /// User denied camera access
        case denied

        /// Camera access is restricted (parental controls, etc.)
        case restricted

        /// Human-readable description
        var description: String {
            switch self {
            case .notDetermined:
                return "Camera permission not yet requested"
            case .authorized:
                return "Camera access authorized"
            case .denied:
                return "Camera access denied by user"
            case .restricted:
                return "Camera access restricted by system"
            }
        }

        /// Icon for this status
        var icon: String {
            switch self {
            case .notDetermined:
                return "questionmark.circle"
            case .authorized:
                return "checkmark.circle.fill"
            case .denied:
                return "xmark.circle.fill"
            case .restricted:
                return "lock.circle.fill"
            }
        }
    }
}

// MARK: - Scene Phase Observer

extension CameraPermissionService {
    /// Re-check permission status when app becomes active
    /// User may have changed permission in Settings
    func onAppBecameActive() {
        let previousStatus = status
        checkStatus()

        // If status changed from denied to authorized, user enabled in Settings
        if previousStatus == .denied && status == .authorized {
            HapticManager.notification(.success)
        }
    }
}
