import SwiftUI
import SwiftData
import AVFoundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

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
    @State private var capturedImage: UIImage?
    @State private var showCropReview = false
    @State private var extractedMetadata: BookMetadata?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false

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
        .fullScreenCover(isPresented: $showCropReview, onDismiss: {
            if !isProcessing {
                capturedImage = nil
            }
        }) {
            if let capturedImage {
                CoverCropReviewView(
                    image: capturedImage,
                    onRetake: {
                        resetCapturedPhoto()
                    },
                    onUse: { croppedImage in
                        resetCapturedPhoto()
                        Task {
                            await processCapturedCover(croppedImage)
                        }
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
            CameraPreviewView(cameraService: cameraService)
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
                let previewCropped = cameraService.cropToPreviewVisibleArea(image)
                await MainActor.run {
                    capturedImage = normalizeOrientation(previewCropped)
                    showCropReview = true
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

    // MARK: - Cover Detection

    /// Attempts to detect and crop the book cover from the captured image.
    /// Falls back to the guide-frame crop when detection fails.
    private func detectCoverCrop(_ image: UIImage) async -> UIImage? {
        let normalized = normalizeOrientation(image)
        guard let cgImage = normalized.cgImage else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let _ = error {
                    continuation.resume(returning: nil)
                    return
                }

                guard let rectangles = request.results as? [VNRectangleObservation],
                      let best = rectangles.max(by: { ($0.boundingBox.width * $0.boundingBox.height) < ($1.boundingBox.width * $1.boundingBox.height) }) else {
                    continuation.resume(returning: nil)
                    return
                }

                let ciImage = CIImage(cgImage: cgImage)
                let size = ciImage.extent.size

                let topLeft = CGPoint(x: best.topLeft.x * size.width, y: best.topLeft.y * size.height)
                let topRight = CGPoint(x: best.topRight.x * size.width, y: best.topRight.y * size.height)
                let bottomLeft = CGPoint(x: best.bottomLeft.x * size.width, y: best.bottomLeft.y * size.height)
                let bottomRight = CGPoint(x: best.bottomRight.x * size.width, y: best.bottomRight.y * size.height)

                let corrected = ciImage.applyingFilter(
                    "CIPerspectiveCorrection",
                    parameters: [
                        "inputTopLeft": CIVector(cgPoint: topLeft),
                        "inputTopRight": CIVector(cgPoint: topRight),
                        "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                        "inputBottomRight": CIVector(cgPoint: bottomRight)
                    ]
                )

                let context = CIContext(options: nil)
                guard let output = context.createCGImage(corrected, from: corrected.extent) else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: UIImage(cgImage: output))
            }

            request.maximumObservations = 5
            request.minimumConfidence = 0.6
            request.minimumAspectRatio = 0.45
            request.maximumAspectRatio = 0.9
            request.minimumSize = 0.25
            request.quadratureTolerance = 20

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
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
        capturedImage = nil
        showCropReview = false
    }

    // MARK: - Extraction (Placeholders)

    private func extractCoverMetadata(from image: UIImage) async -> BookMetadata {
        let coverData = image.jpegData(compressionQuality: 0.85)
        let service = GeminiService(authService: authService)
        let orchestrator = CoverExtractionOrchestrator(
            extractWithGemini: { image in
                try await service.extractCoverMetadata(from: image)
            },
            extractWithOCR: { image, coverImageData in
                await extractCoverMetadataViaOCR(from: image, coverImageData: coverImageData)
            }
        )

        return await orchestrator.extract(from: image, coverImageData: coverData)
    }

    private func extractCoverMetadataViaOCR(from image: UIImage, coverImageData: Data?) async -> BookMetadata {
        guard let cgImage = normalizeOrientation(image).cgImage else {
            return BookMetadata(
                title: "",
                authors: [],
                coverImageData: coverImageData,
                source: .manual
            )
        }

        let observations: [VNRecognizedTextObservation] = await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: (request.results as? [VNRecognizedTextObservation]) ?? [])
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.02

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }

        // Sort top-to-bottom, then left-to-right.
        let lines: [(text: String, box: CGRect)] = observations.compactMap { obs in
            guard let text = obs.topCandidates(1).first?.string else { return nil }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return (trimmed, obs.boundingBox)
        }
        .sorted { a, b in
            if abs(a.box.midY - b.box.midY) > 0.03 {
                return a.box.midY > b.box.midY
            }
            return a.box.minX < b.box.minX
        }

        let cleaned = lines
            .map { (text: CoverOCRHeuristics.sanitizeLine($0.text), box: $0.box) }
            .filter { !$0.text.isEmpty }

        let guess = CoverOCRHeuristics.guessTitleAndAuthor(from: cleaned)
        return BookMetadata(
            title: guess.title,
            authors: CoverMetadataNormalizer.splitAuthors(guess.author),
            coverImageData: coverImageData,
            source: .coverPhoto
        )
    }

    private func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    private func lookupISBN(_ isbn: String) async throws -> BookMetadata {
        let service = ISBNLookupService()
        return try await service.lookup(isbn: isbn)
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
