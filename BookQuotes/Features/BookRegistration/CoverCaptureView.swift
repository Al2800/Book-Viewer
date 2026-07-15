import SwiftUI

// MARK: - Cover Capture View

/// Camera-based ISBN barcode scanner for adding books from catalog metadata.
struct CoverCaptureView: View {
    @Environment(\.dismiss) private var dismiss

    var onComplete: ((Book) -> Void)?
    var onCancel: (() -> Void)?

    @State private var cameraService = CameraService()
    @State private var isbnScanner = ISBNScanner()
    @State private var cameraPermission = CameraPermissionService()
    @State private var extractedMetadata: BookMetadata?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    private let cameraFramingProfile = CameraFramingProfile.cover

    var body: some View {
        ZStack {
            cameraContent
            CoverBarcodeScanOverlay()

            if isProcessing {
                CoverProcessingOverlay(message: "Looking up book...")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top, spacing: 0) {
            CoverCaptureHeader(onCancel: cancelCapture)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CoverCaptureBottomControls(
                isProcessing: isProcessing,
                showsTestISBNButton: UITestConfiguration.isUITesting && !UITestConfiguration.isAppStoreMediaMode,
                onUseTestISBN: useTestISBN,
                onManualEntry: showManualEntry
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $extractedMetadata, onDismiss: resumeScanning) { metadata in
            BookEditView(mode: .createFromMetadata(metadata)) { book in
                onComplete?(book)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                resumeScanning()
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cleanup()
        }
    }

    @ViewBuilder
    private var cameraContent: some View {
        if cameraService.isAuthorized && cameraService.isSessionConfigured {
            CameraPreviewView(cameraService: cameraService, framingProfile: cameraFramingProfile)
                .ignoresSafeArea()
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.cameraPreview)
        } else if cameraService.isAuthorized {
            Color.black
                .ignoresSafeArea()
                .overlay {
                    ProgressView()
                        .tint(.white)
                }
        } else {
            CameraPermissionView()
                .environment(cameraPermission)
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.permissionPrompt)
        }
    }

    private func setupCamera() {
        Task {
            let authorized = await cameraService.requestAuthorization()
            guard authorized else { return }

            do {
                try cameraService.setupSession()
                setupBarcodeCallback()
                resumeScanning()
                cameraService.startSession()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func setupBarcodeCallback() {
        isbnScanner.onBarcodeDetected = { isbn in
            guard !isProcessing else { return }
            handleBarcodeDetected(isbn)
        }
    }

    private func resumeScanning() {
        guard !isProcessing, extractedMetadata == nil,
              let session = cameraService.captureSession else { return }

        isbnScanner.clearResult()
        if !isbnScanner.isScanning {
            isbnScanner.startScanning(on: session)
        }
    }

    private func cleanup() {
        isbnScanner.stopScanning()
        cameraService.cleanup()
    }

    private func handleBarcodeDetected(_ isbn: String) {
        guard !isProcessing else { return }
        isProcessing = true
        isbnScanner.stopScanning()

        Task {
            HapticManager.success()

            do {
                extractedMetadata = try await CoverCaptureMetadataSupport().lookupISBN(isbn)
                isProcessing = false
            } catch {
                isProcessing = false
                errorMessage = "Could not find book: \(error.localizedDescription)"
                showError = true
                HapticManager.error()
            }
        }
    }

    private func useTestISBN() {
        isbnScanner.stopScanning()
        extractedMetadata = BookMetadata(
            title: "Test ISBN Book",
            authors: ["Test Author"],
            isbn13: "9780735211292",
            coverImageData: MockCameraImages.bookCoverImage.jpegData(compressionQuality: 0.85),
            source: .googleBooks
        )
    }

    private func showManualEntry() {
        isbnScanner.stopScanning()
        extractedMetadata = BookMetadata(title: "", authors: [])
    }

    private func cancelCapture() {
        if let onCancel {
            onCancel()
        } else {
            dismiss()
        }
    }
}

// Retained as a small value type for migration tests covering old pending crop state.
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

#Preview {
    CoverCaptureView()
        .modelContainer(for: Book.self, inMemory: true)
}
