import SwiftUI
import SwiftData

// MARK: - Cover Capture View

/// Camera-based view for capturing book covers or scanning ISBN barcodes.
/// Supports Photo mode for AI-based cover extraction and Barcode mode for ISBN lookup.
struct CoverCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    /// Completion handler with the created book
    var onComplete: ((Book) -> Void)?

    /// Handler when user cancels
    var onCancel: (() -> Void)?

    // MARK: - State

    @State private var cameraService = CameraService()
    @State private var isbnScanner = ISBNScanner()
    @State private var cameraPermission = CameraPermissionService()
    @State private var captureMode: CaptureMode = .photo
    @State private var cropLifecycle = CoverCaptureCropLifecycleState()
    @State private var extractedMetadata: BookMetadata?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    private let cameraFramingProfile = CameraFramingProfile.cover

    // MARK: - Body

    var body: some View {
        ZStack {
            cameraContent

            if captureMode == .barcode {
                CoverBarcodeScanOverlay()
            }

            if isProcessing {
                CoverProcessingOverlay(message: processingMessage)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top, spacing: 0) {
            modeSwitcher
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomControls
        }
        // Prevent the system tab bar from overlapping camera capture UI.
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .fullScreenCover(isPresented: $cropLifecycle.isReviewPresented, onDismiss: {
            if let image = cropLifecycle.consumePendingCroppedCoverAfterReviewDismiss(isProcessing: isProcessing) {
                Task {
                    await processCapturedCover(image)
                }
            }
        }) {
            if let capturedImage = cropLifecycle.capturedImage {
                CoverCropReviewView(
                    image: capturedImage,
                    onRetake: {
                        resetCapturedPhoto()
                    },
                    onUse: { croppedImage in
                        cropLifecycle.acceptCrop(croppedImage)
                    }
                )
            }
        }
        .sheet(item: $extractedMetadata) { metadata in
            BookEditView(mode: .createFromMetadata(metadata)) { book in
                onComplete?(book)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cleanup()
        }
        .onChange(of: captureMode) { _, newMode in
            handleModeChange(newMode)
        }
    }

    // MARK: - Camera Content

    @ViewBuilder
    private var cameraContent: some View {
        if cameraService.isAuthorized {
            CameraPreviewView(cameraService: cameraService, framingProfile: cameraFramingProfile)
                .ignoresSafeArea()
        } else {
            CameraPermissionView()
                .environment(cameraPermission)
        }
    }

    // MARK: - Processing Overlay

    private var processingMessage: String {
        switch captureMode {
        case .photo:
            return "Analyzing cover..."
        case .barcode:
            return "Looking up book..."
        }
    }

    // MARK: - Controls Overlay

    private var modeSwitcher: some View {
        CoverCaptureModeSwitcher(
            captureMode: $captureMode,
            onCancel: cancelCapture
        )
    }

    private var bottomControls: some View {
        CoverCaptureBottomControls(
            captureMode: captureMode,
            isProcessing: isProcessing,
            isSessionRunning: cameraService.isSessionRunning,
            showsTestCoverButton: UITestConfiguration.isUITesting && !UITestConfiguration.isAppStoreMediaMode,
            onCapturePhoto: capturePhoto,
            onUseTestCover: captureTestCover,
            onManualEntry: showManualEntry
        )
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        Task {
            let authorized = await cameraService.requestAuthorization()
            guard authorized else { return }

            do {
                try cameraService.setupSession()
                cameraService.startSession()

                // Set up barcode scanning callback
                setupBarcodeScanning()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func setupBarcodeScanning() {
        isbnScanner.onBarcodeDetected = { isbn in
            guard captureMode == .barcode, !isProcessing else { return }
            handleBarcodeDetected(isbn)
        }
    }

    private func handleModeChange(_ mode: CaptureMode) {
        switch mode {
        case .photo:
            isbnScanner.stopScanning()
        case .barcode:
            if let session = cameraService.captureSession {
                isbnScanner.startScanning(on: session)
            }
        }
    }

    private func cleanup() {
        isbnScanner.stopScanning()
        cameraService.cleanup()
    }

    // MARK: - Capture Actions

    private func capturePhoto() {
        Task {
            HapticManager.medium()

            do {
                let image = try await cameraService.capturePhoto()
                let previewSize = cameraService.currentPreviewSizeForCropping()
                let cropBehavior = cameraFramingProfile.captureCropBehavior
                let previewCropped = await Task.detached(priority: .userInitiated) { () -> UIImage in
                    guard cropBehavior == .aspectFillVisibleArea,
                          let previewSize else { return image }
                    return (try? ImagePreprocessor.cropToAspectFillPreview(image, previewSize: previewSize)) ?? image
                }.value
                await MainActor.run {
                    cropLifecycle.presentCapturedImage(CoverCaptureMetadataSupport.normalizeOrientation(previewCropped))
                }

            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.error()
            }
        }
    }

    private func captureTestCover() {
        extractedMetadata = BookMetadata(
            title: "Test Cover Book",
            authors: ["Test Author"],
            source: .coverPhoto
        )
    }

    @MainActor
    private func processCapturedCover(_ image: UIImage) async {
        isProcessing = true
        let metadata = await extractCoverMetadata(from: image)
        extractedMetadata = metadata
        if metadata.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Couldn’t read the cover details. Please enter the title and author manually."
            showError = true
        }
        isProcessing = false
    }

    private func handleBarcodeDetected(_ isbn: String) {
        Task {
            isProcessing = true
            HapticManager.success()

            do {
                // Look up ISBN
                let metadata = try await lookupISBN(isbn)
                extractedMetadata = metadata
                isProcessing = false

            } catch {
                isProcessing = false
                errorMessage = "Could not find book: \(error.localizedDescription)"
                showError = true
                HapticManager.error()
            }
        }
    }

    private func showManualEntry() {
        // Create empty metadata to trigger manual entry
        extractedMetadata = BookMetadata(title: "", authors: [])
    }

    private func cancelCapture() {
        if let onCancel {
            onCancel()
        } else {
            dismiss()
        }
    }

    private func resetCapturedPhoto() {
        cropLifecycle.reset()
    }

    // MARK: - Extraction (Placeholders)

    private func extractCoverMetadata(from image: UIImage) async -> BookMetadata {
        await CoverCaptureMetadataSupport(authService: authService).extractCoverMetadata(from: image)
    }

    private func lookupISBN(_ isbn: String) async throws -> BookMetadata {
        try await CoverCaptureMetadataSupport(authService: authService).lookupISBN(isbn)
    }
}

// MARK: - Cover Crop Lifecycle State

struct CoverCaptureCropLifecycleState {
    var capturedImage: UIImage?
    var pendingCroppedCover: UIImage?
    var isReviewPresented = false

    mutating func presentCapturedImage(_ image: UIImage) {
        capturedImage = image
        pendingCroppedCover = nil
        isReviewPresented = true
    }

    mutating func acceptCrop(_ image: UIImage) {
        pendingCroppedCover = image
        isReviewPresented = false
    }

    mutating func reset() {
        capturedImage = nil
        pendingCroppedCover = nil
        isReviewPresented = false
    }

    mutating func consumePendingCroppedCoverAfterReviewDismiss(isProcessing: Bool) -> UIImage? {
        isReviewPresented = false

        guard let image = pendingCroppedCover else {
            if !isProcessing {
                capturedImage = nil
            }
            return nil
        }

        pendingCroppedCover = nil
        capturedImage = nil
        return image
    }
}

// MARK: - Capture Mode

extension CoverCaptureView {
    enum CaptureMode: String, CaseIterable {
        case photo
        case barcode
    }
}

// MARK: - Preview

#Preview {
    CoverCaptureView()
        .modelContainer(for: Book.self, inMemory: true)
}
