import AVFoundation
import CoreGraphics

enum CameraCaptureCropBehavior: Equatable {
    case none
    case aspectFillVisibleArea
}

enum CameraFramingProfile: Equatable {
    case quotePage
    case cover

    var previewVideoGravity: AVLayerVideoGravity {
        switch self {
        case .quotePage:
            return .resizeAspect
        case .cover:
            return .resizeAspectFill
        }
    }

    var captureCropBehavior: CameraCaptureCropBehavior {
        switch self {
        case .quotePage:
            return .none
        case .cover:
            return .aspectFillVisibleArea
        }
    }

    var guidanceText: String {
        switch self {
        case .quotePage:
            return "Frame the full marked passage, including margin marks and line endings."
        case .cover:
            return "Frame the full cover."
        }
    }
}

enum CameraFramingGeometry {
    static func aspectFillVisibleRect(imageSize: CGSize, previewSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0,
              previewSize.width > 0, previewSize.height > 0 else {
            return .zero
        }

        let targetRatio = previewSize.width / previewSize.height
        let imageRatio = imageSize.width / imageSize.height

        let cropRect: CGRect
        if imageRatio > targetRatio {
            let width = imageSize.height * targetRatio
            cropRect = CGRect(
                x: (imageSize.width - width) / 2,
                y: 0,
                width: width,
                height: imageSize.height
            )
        } else if imageRatio < targetRatio {
            let height = imageSize.width / targetRatio
            cropRect = CGRect(
                x: 0,
                y: (imageSize.height - height) / 2,
                width: imageSize.width,
                height: height
            )
        } else {
            cropRect = CGRect(origin: .zero, size: imageSize)
        }

        return cropRect.integral.intersection(CGRect(origin: .zero, size: imageSize))
    }
}

