import AVFoundation

enum CameraAuthorizationDecision: Equatable {
    case authorized
    case needsRequest
    case denied

    var isAuthorized: Bool {
        self == .authorized
    }

    var shouldRequestAccess: Bool {
        self == .needsRequest
    }
}

enum CameraAuthorizationPolicy {
    static func decision(for status: AVAuthorizationStatus) -> CameraAuthorizationDecision {
        switch status {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .needsRequest
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }

    static func permissionStatus(
        for status: AVAuthorizationStatus
    ) -> CameraPermissionService.PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }
}
