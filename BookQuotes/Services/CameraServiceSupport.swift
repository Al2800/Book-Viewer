import AVFoundation
import SwiftUI

enum CameraError: LocalizedError {
    case notAuthorized
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput
    case inputConfigurationFailed(Error)
    case sessionNotConfigured
    case captureFailed(Error)
    case imageProcessingFailed
    case captureInProgress
    case captureCancelled
    case captureTimedOut

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access not authorized"
        case .cameraUnavailable:
            return "Camera is not available"
        case .cannotAddInput:
            return "Cannot add camera input"
        case .cannotAddOutput:
            return "Cannot add photo output"
        case .inputConfigurationFailed(let error):
            return "Input configuration failed: \(error.localizedDescription)"
        case .sessionNotConfigured:
            return "Camera session not configured"
        case .captureFailed(let error):
            return "Photo capture failed: \(error.localizedDescription)"
        case .imageProcessingFailed:
            return "Failed to process captured image"
        case .captureInProgress:
            return "A photo is already being captured."
        case .captureCancelled:
            return "Camera capture was cancelled."
        case .captureTimedOut:
            return "Camera capture timed out. Please try again."
        }
    }
}

/// Correlates one AVFoundation photo request with its callback so stale callbacks cannot
/// complete a later capture after a timeout or view dismissal.
struct CameraCaptureLifecycle {
    private(set) var activeCaptureID: UUID?
    private(set) var activePhotoSettingsID: Int64?

    var isCapturing: Bool {
        activeCaptureID != nil
    }

    mutating func begin(captureID: UUID, photoSettingsID: Int64) -> Bool {
        guard !isCapturing else { return false }
        activeCaptureID = captureID
        activePhotoSettingsID = photoSettingsID
        return true
    }

    func captureID(matchingPhotoSettingsID photoSettingsID: Int64) -> UUID? {
        guard activePhotoSettingsID == photoSettingsID else { return nil }
        return activeCaptureID
    }

    mutating func finish(captureID: UUID) -> Bool {
        guard activeCaptureID == captureID else { return false }
        reset()
        return true
    }

    mutating func cancel() {
        reset()
    }

    private mutating func reset() {
        activeCaptureID = nil
        activePhotoSettingsID = nil
    }
}

enum CameraCaptureConfiguration {
    static let portraitRotationAngle: CGFloat = 90

    static func maximumPhotoDimensions(
        from supportedDimensions: [CMVideoDimensions]
    ) -> CMVideoDimensions? {
        supportedDimensions.max { lhs, rhs in
            pixelCount(lhs) < pixelCount(rhs)
        }
    }

    static func applyPortraitRotation(to connection: AVCaptureConnection?) {
        guard let connection,
              connection.isVideoRotationAngleSupported(portraitRotationAngle) else {
            return
        }

        connection.videoRotationAngle = portraitRotationAngle
    }

    private static func pixelCount(_ dimensions: CMVideoDimensions) -> Int64 {
        Int64(dimensions.width) * Int64(dimensions.height)
    }
}

enum CameraImageCompressor {
    /// Compress an image for API upload.
    static func compressForUpload(
        _ image: UIImage,
        maxDimension: CGFloat = 2048,
        quality: CGFloat = 0.8
    ) -> Data? {
        let size = image.size
        let newSize = resizedSize(for: size, maxDimension: maxDimension)

        let resizedImage: UIImage
        if newSize != size {
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resizedImage = image
        }

        return resizedImage.jpegData(compressionQuality: quality)
    }

    private static func resizedSize(for size: CGSize, maxDimension: CGFloat) -> CGSize {
        guard size.width > maxDimension || size.height > maxDimension else {
            return size
        }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        return CGSize(width: size.width * ratio, height: size.height * ratio)
    }
}

extension CameraService {
    /// Compress an image for API upload.
    static func compressForUpload(
        _ image: UIImage,
        maxDimension: CGFloat = 2048,
        quality: CGFloat = 0.8
    ) -> Data? {
        CameraImageCompressor.compressForUpload(
            image,
            maxDimension: maxDimension,
            quality: quality
        )
    }
}
