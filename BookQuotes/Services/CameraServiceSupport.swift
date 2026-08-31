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

/// Thread-safe generation token used to invalidate queued capture-session work during teardown.
final class CameraSessionGenerationGate: @unchecked Sendable {
    private let lock = NSLock()
    private var generation: UInt64 = 0

    func activate() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        generation &+= 1
        return generation
    }

    func invalidate() {
        lock.lock()
        generation &+= 1
        lock.unlock()
    }

    func isCurrent(_ token: UInt64) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return generation == token
    }
}

struct CameraFrameProcessingToken: Sendable, Equatable {
    let generation: UInt64
}

/// Limits expensive live Vision work to one request at a time and invalidates old callbacks.
final class CameraFrameProcessingGate: @unchecked Sendable {
    private let lock = NSLock()
    private let minimumInterval: TimeInterval
    private var generation: UInt64 = 0
    private var lastStartedAt: TimeInterval = 0
    private var isBusy = false

    init(minimumInterval: TimeInterval) {
        self.minimumInterval = minimumInterval
    }

    func beginFrame(now: TimeInterval) -> CameraFrameProcessingToken? {
        lock.lock()
        defer { lock.unlock() }

        guard !isBusy else { return nil }
        guard lastStartedAt == 0 || now - lastStartedAt >= minimumInterval else { return nil }

        isBusy = true
        lastStartedAt = now
        return CameraFrameProcessingToken(generation: generation)
    }

    func finish(_ token: CameraFrameProcessingToken) {
        lock.lock()
        if token.generation == generation {
            isBusy = false
        }
        lock.unlock()
    }

    func isCurrent(_ token: CameraFrameProcessingToken) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return token.generation == generation
    }

    func reset() {
        lock.lock()
        generation &+= 1
        lastStartedAt = 0
        isBusy = false
        lock.unlock()
    }
}

enum CameraCaptureConfiguration {
    static let portraitRotationAngle: CGFloat = 90

    /// Approximately 12 MP. This avoids retaining 24–48 MP buffers for routine page capture.
    static let preferredMaxPhotoPixelCount: Int64 = 12_582_912

    static func maximumPhotoDimensions(
        from supportedDimensions: [CMVideoDimensions]
    ) -> CMVideoDimensions? {
        supportedDimensions.max { lhs, rhs in
            pixelCount(lhs) < pixelCount(rhs)
        }
    }

    /// Selects the largest supported still size within the memory budget.
    /// If every supported size exceeds the budget, the smallest available size is used.
    static func preferredPhotoDimensions(
        from supportedDimensions: [CMVideoDimensions],
        maxPixelCount: Int64 = preferredMaxPhotoPixelCount
    ) -> CMVideoDimensions? {
        let withinBudget = supportedDimensions.filter { pixelCount($0) <= maxPixelCount }
        if let bestFit = withinBudget.max(by: { pixelCount($0) < pixelCount($1) }) {
            return bestFit
        }

        return supportedDimensions.min { lhs, rhs in
            pixelCount(lhs) < pixelCount(rhs)
        }
    }

    static func photoFlashMode(
        for flashMode: CaptureFlashMode,
        supported: [AVCaptureDevice.FlashMode]
    ) -> AVCaptureDevice.FlashMode? {
        let requested = flashMode.avFoundationMode
        return supported.contains(requested) ? requested : nil
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

enum VisionBoundingBoxTransformer {
    /// Convert Vision normalized rect (bottom-left origin in landscape/buffer orientation)
    /// to UI portrait normalized rect (top-left origin).
    static func transformVisionRectToUIPortrait(_ visionRect: CGRect) -> CGRect {
        let uiX = visionRect.minY
        let uiY = 1.0 - visionRect.maxX
        let uiWidth = visionRect.height
        let uiHeight = visionRect.width
        return CGRect(
            x: max(0, min(1, uiX)),
            y: max(0, min(1, uiY)),
            width: max(0, min(1, uiWidth)),
            height: max(0, min(1, uiHeight))
        )
    }

    /// Scale a normalized UI rect (0..1) to target view size (points).
    static func scaleNormalizedRect(_ normalizedRect: CGRect, to viewSize: CGSize) -> CGRect {
        guard viewSize.width > 0, viewSize.height > 0 else { return .zero }
        return CGRect(
            x: normalizedRect.origin.x * viewSize.width,
            y: normalizedRect.origin.y * viewSize.height,
            width: normalizedRect.size.width * viewSize.width,
            height: normalizedRect.size.height * viewSize.height
        )
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
