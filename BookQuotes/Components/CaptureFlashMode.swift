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

    var next: CaptureFlashMode {
        switch self {
        case .auto: return .on
        case .on: return .off
        case .off: return .auto
        }
    }
}
