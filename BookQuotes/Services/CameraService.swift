import AVFoundation
import SwiftUI

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

    /// Whether inputs and outputs are ready for a live preview layer.
    private(set) var isSessionConfigured = false

    /// Whether AVFoundation has a photo request awaiting a terminal callback.
    var isCapturing: Bool {
        captureLifecycle.isCapturing
    }

    /// Last captured image
    private(set) var capturedImage: UIImage?

    /// Current camera position (front/back)
    private(set) var cameraPosition: AVCaptureDevice.Position = .back

    /// Hardware flash mode applied to the next still capture.
    private(set) var flashMode: CaptureFlashMode = .auto

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
    private var previewSizeStore = CameraPreviewSizeStore()
    private var configuredPhotoDimensions: CMVideoDimensions?

    // MARK: - Continuations for async capture

    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    private var captureLifecycle = CameraCaptureLifecycle()
    private var photoTimeoutTask: Task<Void, Never>?
    private static let defaultCaptureTimeoutSeconds: UInt64 = 15
    private let sessionQueue = DispatchQueue(label: "com.bookquotes.camera.session")

    // MARK: - Initialization

    override init() {
        self.isMockCameraMode = UITestConfiguration.shouldMockCamera
        super.init()

        if isMockCameraMode {
            // In mock mode, camera is always "authorized" and "running"
            isAuthorized = true
            isSessionConfigured = true
            isSessionRunning = true
        } else {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            isAuthorized = CameraAuthorizationPolicy.decision(for: status).isAuthorized
        }
    }

    // MARK: - Authorization

    /// Check current authorization status
    func checkAuthorization() {
        if isMockCameraMode {
            isAuthorized = true
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        isAuthorized = CameraAuthorizationPolicy.decision(for: status).isAuthorized
    }

    /// Request camera permission
    @discardableResult
    func requestAuthorization() async -> Bool {
        if isMockCameraMode {
            isAuthorized = true
            return true
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch CameraAuthorizationPolicy.decision(for: status) {
        case .authorized:
            isAuthorized = true
            return true

        case .needsRequest:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
            return granted

        case .denied:
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

        if isSessionConfigured, captureSession != nil {
            return
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

        if session.canAddOutput(output) {
            session.addOutput(output)
            configurePhotoDimensions(for: videoDevice, output: output)
            photoOutput = output
        } else {
            throw CameraError.cannotAddOutput
        }

        session.commitConfiguration()
        captureSession = session
        isSessionConfigured = true
    }

    /// Create a preview layer for the camera feed
    func createPreviewLayer(framingProfile: CameraFramingProfile = .quotePage) -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = framingProfile.previewVideoGravity
        CameraCaptureConfiguration.applyPortraitRotation(to: layer.connection)
        previewLayer = layer
        return layer
    }

    /// Update the preview size from the hosting view's layout.
    func updatePreviewSize(_ size: CGSize) {
        previewSizeStore.recordLayoutSize(size)
    }

    /// Best-effort preview size for aspect-fill cropping.
    /// Used to move heavy cropping work off the MainActor while still matching what the user framed.
    func currentPreviewSizeForCropping() -> CGSize? {
        previewSizeStore.currentCroppingSize(previewLayerSize: previewLayer?.bounds.size)
    }

    /// Start the capture session
    func startSession() {
        // In mock mode, session is always "running"
        if isMockCameraMode {
            isSessionRunning = true
            return
        }

        guard let session = captureSession else { return }

        sessionQueue.async { [weak self] in
            if !session.isRunning {
                session.startRunning()
            }
            DispatchQueue.main.async {
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

        guard let session = captureSession else {
            isSessionRunning = false
            return
        }

        sessionQueue.async { [weak self] in
            if session.isRunning {
                session.stopRunning()
            }
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }

    /// Pause on background and resume when the capture flow is visible again.
    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            guard isAuthorized, isSessionConfigured else { return }
            startSession()
        case .background:
            stopSession()
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    /// Cycle auto → on → off for the next still capture.
    func cycleFlashMode() {
        flashMode = flashMode.next
    }

    /// Whether the current input can fire a flash. Mock camera always reports available.
    var isFlashAvailable: Bool {
        if isMockCameraMode {
            return true
        }
        return videoDeviceInput?.device.hasFlash == true
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

        let settings = AVCapturePhotoSettings()
        if let configuredPhotoDimensions {
            settings.maxPhotoDimensions = configuredPhotoDimensions
        }
        if let flash = CameraCaptureConfiguration.photoFlashMode(
            for: flashMode,
            supported: photoOutput.supportedFlashModes
        ) {
            settings.flashMode = flash
        }

        let captureID = UUID()
        guard captureLifecycle.begin(
            captureID: captureID,
            photoSettingsID: settings.uniqueID
        ) else {
            throw CameraError.captureInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            photoContinuation = continuation

            // Safety valve: if AVCapturePhotoOutput never calls back, don't freeze the UI forever.
            // If a later capture starts, the captureID check prevents timing out the wrong request.
            photoTimeoutTask = Task { [weak self] in
                do {
                    try await Task.sleep(nanoseconds: Self.defaultCaptureTimeoutSeconds * 1_000_000_000)
                } catch {
                    return
                }

                guard let self else { return }
                self.completePendingCapture(
                    captureID: captureID,
                    result: .failure(CameraError.captureTimedOut)
                )
            }

            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func completePendingCapture(
        captureID: UUID,
        result: Result<UIImage, Error>
    ) {
        guard captureLifecycle.activeCaptureID == captureID,
              let continuation = photoContinuation,
              captureLifecycle.finish(captureID: captureID) else {
            return
        }

        photoTimeoutTask?.cancel()
        photoTimeoutTask = nil
        photoContinuation = nil

        switch result {
        case .success(let image):
            capturedImage = image
            continuation.resume(returning: image)
        case .failure(let error):
            continuation.resume(throwing: error)
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
                if let photoOutput {
                    configurePhotoDimensions(for: newDevice, output: photoOutput)
                }
            } else {
                session.addInput(currentInput)
                throw CameraError.cannotAddInput
            }

            session.commitConfiguration()
        } catch {
            throw CameraError.inputConfigurationFailed(error)
        }
    }

    // MARK: - Photo Configuration

    private func configurePhotoDimensions(
        for device: AVCaptureDevice,
        output: AVCapturePhotoOutput
    ) {
        let dimensions = CameraCaptureConfiguration.preferredPhotoDimensions(
            from: device.activeFormat.supportedMaxPhotoDimensions
        )
        configuredPhotoDimensions = dimensions

        if let dimensions {
            output.maxPhotoDimensions = dimensions
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
        if let captureID = captureLifecycle.activeCaptureID {
            completePendingCapture(
                captureID: captureID,
                result: .failure(CameraError.captureCancelled)
            )
        }

        photoTimeoutTask?.cancel()
        photoTimeoutTask = nil
        photoContinuation = nil
        captureLifecycle.cancel()

        if isMockCameraMode {
            isSessionRunning = false
            isSessionConfigured = false
            capturedImage = nil
            flashMode = .auto
            return
        }

        let session = captureSession
        sessionQueue.sync {
            if let session, session.isRunning {
                session.stopRunning()
            }
        }

        isSessionRunning = false
        isSessionConfigured = false
        captureSession = nil
        photoOutput = nil
        configuredPhotoDimensions = nil
        videoDeviceInput = nil
        previewLayer = nil
        capturedImage = nil
        flashMode = .auto
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // Keep any heavy work (fileDataRepresentation + JPEG decode) off the MainActor.
        // On some devices this decode can be expensive enough to freeze the capture UI.
        let imageData = photo.fileDataRepresentation()
        let photoSettingsID = photo.resolvedSettings.uniqueID

        Task { @MainActor in
            guard let captureID = captureLifecycle.captureID(
                matchingPhotoSettingsID: photoSettingsID
            ) else {
                return
            }

            if let error = error {
                completePendingCapture(
                    captureID: captureID,
                    result: .failure(CameraError.captureFailed(error))
                )
                return
            }

            guard let imageData else {
                completePendingCapture(
                    captureID: captureID,
                    result: .failure(CameraError.imageProcessingFailed)
                )
                return
            }

            Task.detached(priority: .userInitiated) { [imageData] in
                let image = UIImage(data: imageData)

                Task { @MainActor [weak self] in
                    guard let self else { return }

                    guard let image else {
                        self.completePendingCapture(
                            captureID: captureID,
                            result: .failure(CameraError.imageProcessingFailed)
                        )
                        return
                    }

                    self.completePendingCapture(captureID: captureID, result: .success(image))
                }
            }
        }
    }
}
