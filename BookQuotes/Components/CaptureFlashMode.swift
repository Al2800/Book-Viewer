import AVFoundation
import Foundation

enum CaptureFlashMode: CaseIterable {
    case auto
    case on
    case off

    var icon: String {
        switch self {
        case .auto: return "bolt.badge.automatic"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .auto: return "Flash automatic"
        case .on: return "Flash on"
        case .off: return "Flash off"
        }
    }

    var next: CaptureFlashMode {
        switch self {
        case .auto: return .on
        case .on: return .off
        case .off: return .auto
        }
    }

    var avFoundationMode: AVCaptureDevice.FlashMode {
        switch self {
        case .auto: return .auto
        case .on: return .on
        case .off: return .off
        }
    }
}
