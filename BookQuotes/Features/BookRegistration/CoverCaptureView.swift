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
                barcodeScanOverlay
            }

            if isProcessing {
                processingOverlay
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

    private var barcodeScanOverlay: some View {
        VStack {
            Spacer()

            // Barcode scanner area
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(Color.brand, lineWidth: 3)
                .frame(width: 280, height: 100)
                .overlay {
                    ScanLineView()
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

    private var modeSwitcher: some View {
        VStack(spacing: Spacing.md) {
            CaptureHeaderBar(
                title: "Add Book",
                subtitle: captureMode == .photo ? "Scan the cover or switch to ISBN" : "Scan the ISBN barcode",
                onCancel: cancelCapture
            )

            Picker("Mode", selection: $captureMode) {
                Label("Photo", systemImage: "camera.fill").tag(CaptureMode.photo)
                Label("Barcode", systemImage: "barcode.viewfinder").tag(CaptureMode.barcode)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.modePicker)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .cameraChrome(cornerRadius: CornerRadius.xl)
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }

    private var bottomControls: some View {
        CaptureControlTray {
            if let statusPill = coverStatusPill {
                statusPill
                    .frame(maxWidth: .infinity, alignment: .center)
            }

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
                    Text(captureMode == .photo ? "Enter details manually" : "Enter ISBN manually")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .glassButton()
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.md)
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
        Task {
            let image = MockCameraImages.getTestImage(
                multipleQuotes: false,
                lowConfidence: false,
                index: 0
            )
            await MainActor.run {
                capturedImage = normalizeOrientation(image)
                showCropReview = true
            }
        }
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

    private var coverStatusPill: CaptureStatusPill? {
        if isProcessing {
            let text = captureMode == .photo ? "Reading cover…" : "Looking up ISBN…"
            return CaptureStatusPill(systemImage: "viewfinder", text: text)
        }

        switch captureMode {
        case .photo:
            return nil
        case .barcode:
            return CaptureStatusPill(
                systemImage: "barcode.viewfinder",
                text: "Hold the barcode steady inside the scanner"
            )
        }
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

        do {
            let result = try await service.extractCoverMetadata(from: image)
            var authors = splitAuthors(result.author)
            let isbnValue = result.isbn?.trimmingCharacters(in: .whitespacesAndNewlines)
            let isbn10 = isbnValue?.count == 10 ? isbnValue : nil
            let isbn13 = isbnValue?.count == 13 ? isbnValue : nil
            let categories = result.genre.map { [$0] } ?? []

            // If Gemini fails to read key fields but did not throw, use OCR to backfill.
            let titleTrimmed = result.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if titleTrimmed.isEmpty || authors.isEmpty {
                let ocr = await extractCoverMetadataViaOCR(from: image, coverImageData: coverData)
                if titleTrimmed.isEmpty, !ocr.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return ocr
                }
                if authors.isEmpty, !ocr.authors.isEmpty {
                    authors = ocr.authors
                }
            }

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
            // Gemini can fail due to network/model issues. Fall back to on-device OCR to prefill.
            let ocrFallback = await extractCoverMetadataViaOCR(from: image, coverImageData: coverData)
            if !ocrFallback.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return ocrFallback
            }

            // Final fallback: manual entry but keep cover image.
            return BookMetadata(
                title: "",
                authors: [],
                coverImageData: coverData,
                source: .manual
            )
        }
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
            authors: guess.author.isEmpty ? [] : splitAuthors(guess.author),
            coverImageData: coverImageData,
            source: .coverPhoto
        )
    }

    // NOTE: cover OCR heuristics live in `CoverOCRHeuristics` below so we can unit test them.

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

// MARK: - CoverOCRHeuristics

/// Pure heuristics used by the OCR cover fallback to derive title/author from Vision text lines.
///
/// Kept outside the SwiftUI view so we can test deterministically.
struct CoverOCRHeuristics {

    static func sanitizeLine(_ line: String) -> String {
        var s = line
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Drop common UI/irrelevant strings if they leak into the crop.
        let lowered = s.lowercased()
        if lowered.contains("cancel") ||
            lowered.contains("add book") ||
            lowered.contains("add new book") ||
            lowered.contains("confirm book") {
            return ""
        }

        // Drop barcode/ISBN-heavy lines.
        let digitCount = s.filter { $0.isNumber }.count
        if digitCount >= max(5, s.count / 3) {
            return ""
        }

        // Remove leading "BY " patterns.
        if lowered.hasPrefix("by ") {
            s = String(s.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return s
    }

    static func guessTitleAndAuthor(from lines: [(text: String, box: CGRect)]) -> (title: String, author: String) {
        guard !lines.isEmpty else { return ("", "") }

        // Prefer text near the top for title.
        let topLines = lines.filter { $0.box.midY > 0.55 }.map(\.text)
        let allLines = lines.map(\.text)
        let titleSource = topLines.isEmpty ? allLines : topLines

        let title = buildTitle(from: titleSource)
        let author = findAuthor(in: lines) ?? ""
        return (title, author)
    }

    private static func buildTitle(from lines: [String]) -> String {
        var parts: [String] = []
        var total = 0
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard t.count >= 3 else { continue }
            if t.lowercased().contains("isbn") { continue }
            parts.append(t)
            total += t.count
            if parts.count >= 3 || total >= 40 {
                break
            }
        }
        return parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func findAuthor(in lines: [(text: String, box: CGRect)]) -> String? {
        // Explicit "by <author>"
        for item in lines {
            let lowered = item.text.lowercased()
            if lowered.hasPrefix("by ") {
                return String(item.text.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let range = lowered.range(of: " by ") {
                let author = item.text[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                if author.count >= 3 { return author }
            }
        }

        // Otherwise pick a plausible line near the bottom.
        //
        // Prefer the lowest candidate (closest to the bottom edge), since subtitles often appear
        // above the author and can otherwise be misclassified.
        let bottomCandidates = lines
            .filter { $0.box.midY < 0.45 }
            .sorted { $0.box.midY < $1.box.midY } // lowest first
            .map(\.text)
            .filter { $0.count >= 5 && $0.count <= 40 }
            .filter { !$0.lowercased().contains("isbn") }

        // Heuristic: 2-4 "words" looks like a name.
        for text in bottomCandidates {
            let words = text.split(separator: " ")
            if (2...5).contains(words.count) {
                return text
            }
        }
        return bottomCandidates.first
    }
}

// MARK: - Capture Mode

extension CoverCaptureView {
    enum CaptureMode: String, CaseIterable {
        case photo
        case barcode
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

private struct CoverCropReviewView: View {
    let image: UIImage
    let onRetake: () -> Void
    let onUse: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewportSize: CGSize = .zero
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let maxZoomScale: CGFloat = 4.0

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                cropViewport
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: Spacing.sm) {
                    Text("Adjust Cover Crop")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)

                    Text("Move and zoom the photo until the full cover sits inside the frame.")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Spacing.xl)

                HStack(spacing: Spacing.lg) {
                    Button {
                        onRetake()
                        dismiss()
                    } label: {
                        Label("Retake", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.textSecondary)

                    Button {
                        onUse(croppedImage())
                        dismiss()
                    } label: {
                        Label("Use Crop", systemImage: "checkmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .glassButton()
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .padding(.top, Spacing.lg)
            .background(Color.backgroundPrimary)
            .navigationTitle("Cover")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onRetake()
                        dismiss()
                    }
                }
            }
        }
    }

    private var cropViewport: some View {
        GeometryReader { geometry in
            let size = cropViewportSize(for: geometry.size)

            ZStack {
                Color.black

                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: displayedImageSize(in: size).width, height: displayedImageSize(in: size).height)
                        .offset(clampedOffset(in: size))
                }
                .frame(width: size.width, height: size.height)
                .clipped()
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.35), radius: 16, y: 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let proposedScale = max(1.0, min(lastZoomScale * value, maxZoomScale))
                            zoomScale = proposedScale
                            imageOffset = clampedOffset(in: size)
                        }
                        .onEnded { _ in
                            zoomScale = max(1.0, min(zoomScale, maxZoomScale))
                            lastZoomScale = zoomScale
                            imageOffset = clampedOffset(in: size)
                            lastOffset = imageOffset
                        },
                    DragGesture()
                        .onChanged { value in
                            let proposedOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            imageOffset = clampedOffset(proposedOffset, in: size)
                        }
                        .onEnded { _ in
                            imageOffset = clampedOffset(imageOffset, in: size)
                            lastOffset = imageOffset
                        }
                )
            )
            .onAppear {
                viewportSize = size
                imageOffset = clampedOffset(in: size)
                lastOffset = imageOffset
            }
            .onChange(of: geometry.size) { _, _ in
                viewportSize = size
                imageOffset = clampedOffset(in: size)
                lastOffset = imageOffset
            }
        }
    }

    private func cropViewportSize(for availableSize: CGSize) -> CGSize {
        let maxWidth = min(availableSize.width - (Spacing.xl * 2), 340)
        let height = maxWidth * 1.5
        let constrainedHeight = min(height, max(220, availableSize.height - 140))
        let width = constrainedHeight / 1.5
        return CGSize(width: width, height: constrainedHeight)
    }

    private func baseScale(for viewport: CGSize) -> CGFloat {
        let normalized = normalizedImage
        guard normalized.size.width > 0, normalized.size.height > 0 else { return 1.0 }
        return max(viewport.width / normalized.size.width, viewport.height / normalized.size.height)
    }

    private func displayedImageSize(in viewport: CGSize) -> CGSize {
        let normalized = normalizedImage
        let totalScale = baseScale(for: viewport) * zoomScale
        return CGSize(
            width: normalized.size.width * totalScale,
            height: normalized.size.height * totalScale
        )
    }

    private func clampedOffset(in viewport: CGSize) -> CGSize {
        clampedOffset(imageOffset, in: viewport)
    }

    private func clampedOffset(_ proposedOffset: CGSize, in viewport: CGSize) -> CGSize {
        let displayedSize = displayedImageSize(in: viewport)
        let maxX = max(0, (displayedSize.width - viewport.width) / 2)
        let maxY = max(0, (displayedSize.height - viewport.height) / 2)

        return CGSize(
            width: min(max(proposedOffset.width, -maxX), maxX),
            height: min(max(proposedOffset.height, -maxY), maxY)
        )
    }

    private var normalizedImage: UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    private func croppedImage() -> UIImage {
        let normalized = normalizedImage
        guard let cgImage = normalized.cgImage,
              viewportSize.width > 0,
              viewportSize.height > 0 else {
            return normalized
        }

        let displayedSize = displayedImageSize(in: viewportSize)
        let totalScale = displayedSize.width / normalized.size.width
        guard totalScale > 0 else { return normalized }

        let clamped = clampedOffset(in: viewportSize)
        let displayedOrigin = CGPoint(
            x: (viewportSize.width - displayedSize.width) / 2 + clamped.width,
            y: (viewportSize.height - displayedSize.height) / 2 + clamped.height
        )

        let cropRectInPoints = CGRect(
            x: (0 - displayedOrigin.x) / totalScale,
            y: (0 - displayedOrigin.y) / totalScale,
            width: viewportSize.width / totalScale,
            height: viewportSize.height / totalScale
        ).intersection(CGRect(origin: .zero, size: normalized.size))

        guard !cropRectInPoints.isNull, !cropRectInPoints.isEmpty else {
            return normalized
        }

        let pixelScaleX = CGFloat(cgImage.width) / normalized.size.width
        let pixelScaleY = CGFloat(cgImage.height) / normalized.size.height
        let cropRectInPixels = CGRect(
            x: cropRectInPoints.minX * pixelScaleX,
            y: cropRectInPoints.minY * pixelScaleY,
            width: cropRectInPoints.width * pixelScaleX,
            height: cropRectInPoints.height * pixelScaleY
        ).integral.intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))

        guard let cropped = cgImage.cropping(to: cropRectInPixels) else {
            return normalized
        }

        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }
}

// MARK: - Preview

#Preview {
    CoverCaptureView()
        .modelContainer(for: Book.self, inMemory: true)
}
