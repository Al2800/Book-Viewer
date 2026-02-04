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
    @State private var captureState: CaptureState = .previewing
    @State private var capturedImage: UIImage?
    @State private var extractedMetadata: BookMetadata?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    @State private var previewFrame: CGRect = .zero
    @State private var guideFrame: CGRect = .zero

    private let coordinateSpaceName = "coverCapture"

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Camera preview
                cameraContent

                // Mode-specific overlay
                captureOverlay

                // Processing indicator
                if isProcessing {
                    processingOverlay
                }

                // Capture controls
                controlsOverlay
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                updatePreviewFrame(size: proxy.size)
            }
            .onChange(of: proxy.size) { _, newSize in
                updatePreviewFrame(size: newSize)
            }
        }
        .coordinateSpace(name: coordinateSpaceName)
        .navigationTitle("Add Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
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

    // MARK: - Capture Overlay

    @ViewBuilder
    private var captureOverlay: some View {
        switch captureMode {
        case .photo:
            photoCaptureOverlay
        case .barcode:
            barcodeScanOverlay
        }
    }

    private var photoCaptureOverlay: some View {
        GeometryReader { proxy in
            let maxWidth = min(proxy.size.width * 0.72, 320)
            let frameHeight = maxWidth * 1.5

            VStack {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "viewfinder")
                        .font(.caption)
                    Text("Align cover inside the frame")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.top, Spacing.lg)

                Spacer()

                // Guide frame
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .frame(width: maxWidth, height: frameHeight) // 2:3 cover aspect
                    .overlay {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "book.closed")
                                .font(.title)
                                .foregroundStyle(.white.opacity(0.6))

                            Text("Fill the frame — we’ll auto-crop the cover")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .background(
                        GeometryReader { frameProxy in
                            Color.clear.preference(
                                key: CoverGuideFramePreferenceKey.self,
                                value: frameProxy.frame(in: .named(coordinateSpaceName))
                            )
                        }
                    )

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onPreferenceChange(CoverGuideFramePreferenceKey.self) { rect in
            guideFrame = rect
        }
    }

    private var barcodeScanOverlay: some View {
        VStack {
            Spacer()

            // Barcode scanner area
            VStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(Color.brand, lineWidth: 3)
                    .frame(width: 280, height: 100)
                    .overlay {
                        // Scan line animation
                        ScanLineView()
                    }

                Text("Align barcode within frame")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(processingMessage)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
    }

    private var processingMessage: String {
        switch captureMode {
        case .photo:
            return "Analyzing cover..."
        case .barcode:
            return "Looking up book..."
        }
    }

    // MARK: - Controls Overlay

    private var controlsOverlay: some View {
        VStack(spacing: Spacing.lg) {
            // Mode switcher at top
            Picker("Mode", selection: $captureMode) {
                Label("Photo", systemImage: "camera.fill").tag(CaptureMode.photo)
                Label("Barcode", systemImage: "barcode.viewfinder").tag(CaptureMode.barcode)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.modePicker)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .glassFloating(cornerRadius: CornerRadius.lg)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)

            Spacer()

            VStack(spacing: Spacing.md) {
                if captureMode == .photo && !isProcessing {
                    CaptureButton(isProcessing: isProcessing) {
                        capturePhoto()
                    }
                    .disabled(!cameraService.isSessionRunning)

                    if UITestConfiguration.isUITesting && !UITestConfiguration.isAppStoreMediaMode {
                        Button("Use Test Cover") {
                            captureTestCover()
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.testCoverButton)
                    }
                }

                if !isProcessing {
                    Button {
                        showManualEntry()
                    } label: {
                        Text("Enter manually")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .glassButton()
                }
            }
            .padding(Spacing.lg)
            .glassFloating(cornerRadius: CornerRadius.xl)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                onCancel?()
                dismiss()
            }
        }
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
            isProcessing = true
            HapticManager.medium()

            do {
                let image = try await cameraService.capturePhoto()
                let previewCropped = cameraService.cropToPreviewVisibleArea(image)
                let framed = cropToGuideFrame(previewCropped)
                let autoCropped = await cameraService.autoCropDocument(framed)
                await handleCapturedCover(autoCropped)

            } catch {
                isProcessing = false
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.error()
            }
        }
    }

    private func captureTestCover() {
        Task {
            isProcessing = true
            let image = MockCameraImages.getTestImage(
                multipleQuotes: false,
                lowConfidence: false,
                index: 0
            )
            await handleCapturedCover(image)
        }
    }

    @MainActor
    private func handleCapturedCover(_ image: UIImage) async {
        let detected = await detectCoverCrop(image)
        let cropped = detected ?? cropCoverImage(image)
        capturedImage = cropped

        let metadata = await extractCoverMetadata(from: cropped)
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

    // MARK: - Extraction (Placeholders)

    private func extractCoverMetadata(from image: UIImage) async -> BookMetadata {
        let coverData = image.jpegData(compressionQuality: 0.85)
        let service = GeminiService(authService: authService)

        do {
            let result = try await service.extractCoverMetadata(from: image)
            let authors = splitAuthors(result.author)
            let isbnValue = result.isbn?.trimmingCharacters(in: .whitespacesAndNewlines)
            let isbn10 = isbnValue?.count == 10 ? isbnValue : nil
            let isbn13 = isbnValue?.count == 13 ? isbnValue : nil
            let categories = result.genre.map { [$0] } ?? []

            return BookMetadata(
                title: result.title,
                subtitle: result.subtitle,
                authors: authors,
                publisher: result.publisher,
                publishedYear: result.publishYear,
                isbn10: isbn10,
                isbn13: isbn13,
                categories: categories,
                coverImageData: coverData,
                source: .coverPhoto
            )
        } catch {
            // Fall back to manual entry but keep cover image
            var fallback = BookMetadata(title: "", authors: [], source: .manual)
            fallback.coverImageData = coverData
            return fallback
        }
    }

    private func splitAuthors(_ raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if trimmed.contains("&") {
            return trimmed
                .split(separator: "&")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }

        if trimmed.localizedCaseInsensitiveContains(" and ") {
            return trimmed
                .components(separatedBy: " and ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }

        if trimmed.contains(",") {
            let parts = trimmed
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            return parts.filter { !$0.isEmpty }
        }

        return [trimmed]
    }

    private func cropCoverImage(_ image: UIImage) -> UIImage {
        let normalized = normalizeOrientation(image)
        guard let cgImage = normalized.cgImage else { return normalized }

        let targetRatio: CGFloat = 2.0 / 3.0
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
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
            return normalized
        }

        guard let cropped = cgImage.cropping(to: cropRect) else { return normalized }
        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }

    private func updatePreviewFrame(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        previewFrame = CGRect(origin: .zero, size: size)
    }

    private func cropToGuideFrame(_ image: UIImage) -> UIImage {
        guard let normalized = normalizedGuideRect() else {
            return image
        }
        return cameraService.cropToNormalizedRect(image, normalizedRect: normalized)
    }

    private func normalizedGuideRect() -> CGRect? {
        guard previewFrame.width > 0, previewFrame.height > 0,
              guideFrame.width > 0, guideFrame.height > 0 else {
            return nil
        }

        let intersection = guideFrame.intersection(previewFrame)
        guard !intersection.isNull, !intersection.isEmpty else { return nil }

        let x = (intersection.minX - previewFrame.minX) / previewFrame.width
        let y = (intersection.minY - previewFrame.minY) / previewFrame.height
        let width = intersection.width / previewFrame.width
        let height = intersection.height / previewFrame.height

        let rect = CGRect(x: x, y: y, width: width, height: height)
        let normalized = rect.standardized

        let minX = max(0, min(1, normalized.minX))
        let minY = max(0, min(1, normalized.minY))
        let maxX = max(minX, min(1, normalized.maxX))
        let maxY = max(minY, min(1, normalized.maxY))

        let clamped = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return clamped.width > 0 && clamped.height > 0 ? clamped : nil
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

    enum CaptureState {
        case previewing
        case processing
        case reviewing
    }
}

// MARK: - Guide Frame Preference

private struct CoverGuideFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Scan Line View

/// Animated scan line for barcode mode
struct ScanLineView: View {
    @State private var offset: CGFloat = -30

    var body: some View {
        Rectangle()
            .fill(Color.brand)
            .frame(height: 2)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = 30
                }
            }
    }
}

// MARK: - Preview

#Preview {
    CoverCaptureView()
        .modelContainer(for: Book.self, inMemory: true)
}
