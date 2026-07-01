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
        case .captureTimedOut:
            return "Camera capture timed out. Please try again."
        }
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
