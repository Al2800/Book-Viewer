import AVFoundation
import CoreImage
import SwiftUI
import Vision

/// Camera service for capturing book cover and page photos.
/// Handles AVFoundation session management, permissions, and photo capture.
///
/// When running under UI tests with `--mock-camera`, this service returns
/// sample images from the bundle instead of using the real camera.
@MainActor
@Observable
final class CameraService: NSObject {
    // MARK: - Published State

    /// Whether camera access is authorized
    private(set) var isAuthorized = false

    /// Whether the camera session is currently running
    private(set) var isSessionRunning = false

    /// Last captured image
    private(set) var capturedImage: UIImage?

    /// Current camera position (front/back)
    private(set) var cameraPosition: AVCaptureDevice.Position = .back

    /// Any error that occurred
    private(set) var error: CameraError?

    // MARK: - Mock Camera State (UI Tests Only)

    /// Whether mock camera mode is active
    private let isMockCameraMode: Bool

    /// Mock image index for cycling through test images
    private var mockImageIndex = 0

    // MARK: - AVFoundation Properties

    private(set) var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastPreviewSize: CGSize?

    // MARK: - Continuations for async capture

    private var photoContinuation: CheckedContinuation<UIImage, Error>?

    // MARK: - Initialization

    override init() {
        self.isMockCameraMode = UITestConfiguration.shouldMockCamera
        super.init()

        if isMockCameraMode {
            // In mock mode, camera is always "authorized" and "running"
            isAuthorized = true
            isSessionRunning = true
        }
    }

    // MARK: - Authorization

    /// Check current authorization status
    func checkAuthorization() {
        if isMockCameraMode {
            isAuthorized = true
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined, .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }

    /// Request camera permission
    @discardableResult
    func requestAuthorization() async -> Bool {
        if isMockCameraMode {
            isAuthorized = true
            return true
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            isAuthorized = true
            return true

        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
            return granted

        case .denied, .restricted:
            isAuthorized = false
            return false

        @unknown default:
            isAuthorized = false
            return false
        }
    }

    // MARK: - Session Management

    /// Set up the capture session with back camera
    func setupSession() throws {
        // In mock mode, no actual session setup needed
        if isMockCameraMode {
            return
        }

        guard isAuthorized else {
            throw CameraError.notAuthorized
        }

        let session = AVCaptureSession()
        session.beginConfiguration()

        // Configure for high-quality photo capture
        session.sessionPreset = .photo

        // Add video input (back camera)
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.cameraUnavailable
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                videoDeviceInput = videoInput
            } else {
                throw CameraError.cannotAddInput
            }
        } catch {
            throw CameraError.inputConfigurationFailed(error)
        }

        // Add photo output
        let output = AVCapturePhotoOutput()
        output.isHighResolutionCaptureEnabled = true

        if session.canAddOutput(output) {
            session.addOutput(output)
            photoOutput = output
        } else {
            throw CameraError.cannotAddOutput
        }

        session.commitConfiguration()
        captureSession = session
    }

    /// Create a preview layer for the camera feed
    func createPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        if let connection = layer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        previewLayer = layer
        return layer
    }

    /// Update the preview size from the hosting view's layout.
    func updatePreviewSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        lastPreviewSize = size
    }

    /// Start the capture session
    func startSession() {
        // In mock mode, session is always "running"
        if isMockCameraMode {
            isSessionRunning = true
            return
        }

        guard let session = captureSession, !session.isRunning else { return }

        Task.detached(priority: .userInitiated) { [weak self] in
            session.startRunning()
            await MainActor.run {
                self?.isSessionRunning = true
            }
        }
    }

    /// Stop the capture session
    func stopSession() {
        // In mock mode, just update state
        if isMockCameraMode {
            isSessionRunning = false
            return
        }

        guard let session = captureSession, session.isRunning else { return }

        Task.detached(priority: .userInitiated) { [weak self] in
            session.stopRunning()
            await MainActor.run {
                self?.isSessionRunning = false
            }
        }
    }

    // MARK: - Photo Capture

    /// Capture a photo and return it as UIImage
    func capturePhoto() async throws -> UIImage {
        // In mock mode, return a test image from the bundle
        if isMockCameraMode {
            return try captureMockPhoto()
        }

        guard let photoOutput = photoOutput else {
            throw CameraError.sessionNotConfigured
        }

        return try await withCheckedThrowingContinuation { continuation in
            photoContinuation = continuation

            let settings = AVCapturePhotoSettings()
            settings.isHighResolutionPhotoEnabled = true

            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    /// Capture a mock photo for UI testing
    private func captureMockPhoto() throws -> UIImage {
        // Get the appropriate mock image based on test configuration
        let image = MockCameraImages.getTestImage(
            multipleQuotes: UITestConfiguration.shouldMockMultipleQuotes,
            lowConfidence: UITestConfiguration.shouldMockLowConfidence,
            index: mockImageIndex
        )

        // Cycle through available images for multiple captures
        mockImageIndex += 1

        capturedImage = image
        return image
    }

    /// Clear the last captured image
    func clearCapturedImage() {
        capturedImage = nil
    }

    /// Crop a captured image to match what is visible in the preview layer.
    /// This keeps the saved photo aligned with the user's framing when the preview is aspect-filled.
    func cropToPreviewVisibleArea(_ image: UIImage) -> UIImage {
        guard let previewLayer else { return image }

        let normalized = normalizeImage(image)
        guard let cgImage = normalized.cgImage else { return image }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        let previewSize = previewLayer.bounds.size.width > 0 && previewLayer.bounds.size.height > 0
            ? previewLayer.bounds.size
            : (lastPreviewSize ?? .zero)
        guard previewSize.width > 0, previewSize.height > 0 else { return image }

        let targetRatio = previewSize.width / previewSize.height
        let currentRatio = width / height

        let cropRect: CGRect
        if currentRatio > targetRatio {
            let newWidth = height * targetRatio
            let x = (width - newWidth) / 2.0
            cropRect = CGRect(x: x, y: 0, width: newWidth, height: height)
        } else if currentRatio < targetRatio {
            let newHeight = width / targetRatio
            let y = (height - newHeight) / 2.0
            cropRect = CGRect(x: 0, y: y, width: width, height: newHeight)
        } else {
            cropRect = CGRect(x: 0, y: 0, width: width, height: height)
        }

        let safeRect = cropRect.integral.intersection(CGRect(x: 0, y: 0, width: width, height: height))
        guard let croppedImage = cgImage.cropping(to: safeRect) else { return image }

        return UIImage(cgImage: croppedImage, scale: normalized.scale, orientation: .up)
    }

    /// Crop a captured image to a normalized rect (0-1) relative to the image bounds.
    /// Useful for aligning a UI guide frame with the final captured image.
    func cropToNormalizedRect(_ image: UIImage, normalizedRect: CGRect) -> UIImage {
        let normalized = normalizeImage(image)
        guard let cgImage = normalized.cgImage else { return image }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        let clamped = clampNormalizedRect(normalizedRect)
        guard clamped.width > 0, clamped.height > 0 else { return image }

        let cropRect = CGRect(
            x: clamped.minX * width,
            y: clamped.minY * height,
            width: clamped.width * width,
            height: clamped.height * height
        )

        let safeRect = cropRect.integral.intersection(CGRect(x: 0, y: 0, width: width, height: height))
        guard let croppedImage = cgImage.cropping(to: safeRect) else { return image }

        return UIImage(cgImage: croppedImage, scale: normalized.scale, orientation: .up)
    }

    private func clampNormalizedRect(_ rect: CGRect) -> CGRect {
        let normalized = rect.standardized
        let minX = max(0, min(1, normalized.minX))
        let minY = max(0, min(1, normalized.minY))
        let maxX = max(minX, min(1, normalized.maxX))
        let maxY = max(minY, min(1, normalized.maxY))
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Attempt to auto-crop a document/page by detecting the largest rectangle.
    /// Falls back to the original image if no rectangle is detected.
    func autoCropDocument(_ image: UIImage) async -> UIImage {
        guard !isMockCameraMode else { return image }

        let normalized = normalizeImage(image)
        guard let cgImage = normalized.cgImage else { return image }
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent

        return await withCheckedContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, _ in
                guard let observation = (request.results as? [VNRectangleObservation])?.first else {
                    continuation.resume(returning: image)
                    return
                }

                let width = extent.width
                let height = extent.height

                let topLeft = CGPoint(x: observation.topLeft.x * width, y: observation.topLeft.y * height)
                let topRight = CGPoint(x: observation.topRight.x * width, y: observation.topRight.y * height)
                let bottomLeft = CGPoint(x: observation.bottomLeft.x * width, y: observation.bottomLeft.y * height)
                let bottomRight = CGPoint(x: observation.bottomRight.x * width, y: observation.bottomRight.y * height)

                let corrected = ciImage.applyingFilter(
                    "CIPerspectiveCorrection",
                    parameters: [
                        "inputTopLeft": CIVector(cgPoint: topLeft),
                        "inputTopRight": CIVector(cgPoint: topRight),
                        "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                        "inputBottomRight": CIVector(cgPoint: bottomRight)
                    ]
                )

                let context = CIContext(options: [.useSoftwareRenderer: false])
                if let output = context.createCGImage(corrected, from: corrected.extent) {
                    let result = UIImage(cgImage: output, scale: normalized.scale, orientation: .up)
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(returning: image)
                }
            }

            request.maximumObservations = 1
            request.minimumConfidence = 0.6
            request.minimumAspectRatio = 0.5
            request.minimumSize = 0.3

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    // MARK: - Camera Switching

    /// Switch between front and back camera
    func switchCamera() throws {
        guard let session = captureSession,
              let currentInput = videoDeviceInput else {
            throw CameraError.sessionNotConfigured
        }

        let newPosition: AVCaptureDevice.Position = cameraPosition == .back ? .front : .back

        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            throw CameraError.cameraUnavailable
        }

        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)

            session.beginConfiguration()
            session.removeInput(currentInput)

            if session.canAddInput(newInput) {
                session.addInput(newInput)
                videoDeviceInput = newInput
                cameraPosition = newPosition
            } else {
                session.addInput(currentInput)
                throw CameraError.cannotAddInput
            }

            session.commitConfiguration()
        } catch {
            throw CameraError.inputConfigurationFailed(error)
        }
    }

    // MARK: - Focus

    /// Focus at a specific point in the preview
    func focus(at point: CGPoint) {
        guard let device = videoDeviceInput?.device,
              device.isFocusPointOfInterestSupported else {
            return
        }

        do {
            try device.lockForConfiguration()
            device.focusPointOfInterest = point
            device.focusMode = .autoFocus

            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }

            device.unlockForConfiguration()
        } catch {
            // Focus adjustment failed, ignore silently
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        stopSession()
        captureSession = nil
        photoOutput = nil
        videoDeviceInput = nil
        previewLayer = nil
        capturedImage = nil
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        Task { @MainActor in
            if let error = error {
                photoContinuation?.resume(throwing: CameraError.captureFailed(error))
                photoContinuation = nil
                return
            }

            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                photoContinuation?.resume(throwing: CameraError.imageProcessingFailed)
                photoContinuation = nil
                return
            }

            // Store the captured image
            capturedImage = image

            photoContinuation?.resume(returning: image)
            photoContinuation = nil
        }
    }
}

// MARK: - Camera Errors

enum CameraError: LocalizedError {
    case notAuthorized
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput
    case inputConfigurationFailed(Error)
    case sessionNotConfigured
    case captureFailed(Error)
    case imageProcessingFailed

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
        }
    }
}

// MARK: - Image Compression

extension CameraService {
    /// Compress an image for API upload
    /// - Parameters:
    ///   - image: The image to compress
    ///   - maxDimension: Maximum dimension (width or height)
    ///   - quality: JPEG compression quality (0.0-1.0)
    /// - Returns: Compressed JPEG data
    static func compressForUpload(_ image: UIImage, maxDimension: CGFloat = 2048, quality: CGFloat = 0.8) -> Data? {
        // Calculate new size maintaining aspect ratio
        let size = image.size
        var newSize = size

        if size.width > maxDimension || size.height > maxDimension {
            let ratio = min(maxDimension / size.width, maxDimension / size.height)
            newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        }

        // Resize if needed
        let resizedImage: UIImage
        if newSize != size {
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resizedImage = image
        }

        // Compress to JPEG
        return resizedImage.jpegData(compressionQuality: quality)
    }
}

// MARK: - Image Normalization

private extension CameraService {
    func normalizeImage(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        format.opaque = true

        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
