import SwiftUI
import AVFoundation
import SwiftData

// MARK: - Quote Capture View

/// Single-page quote capture view with camera preview, capture, and review flow.
/// Provides a streamlined path for capturing one quote at a time.
struct QuoteCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// The book to attach quotes to
    let book: Book

    /// Completion handler when capture flow finishes
    var onComplete: (() -> Void)?

    // MARK: - State

    @State private var cameraService = CameraService()
    @State private var qualityAnalyzer = ImageQualityAnalyzer(configuration: .lenient)
    @State private var cameraPermission = CameraPermissionService()
    @State private var captureState: CaptureState = .previewing
    @State private var capturedImage: UIImage?
    @State private var qualityResult: ImageQualityAnalyzer.QualityResult?
    @State private var isAnalyzingQuality = false
    @State private var showQualityOverlay = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showExtractionReview = false
    @State private var capturedSession: CaptureSession?

    // MARK: - Body

    var body: some View {
        ZStack {
            // Camera preview / captured image
            cameraContent

            // Top HUD
            if captureState == .previewing {
                topHud
            }

            // Quality overlay
            if showQualityOverlay && captureState == .previewing {
                qualityOverlayContent
            }

            // Capture controls
            if captureState == .previewing {
                captureControls
            }
        }
        .navigationTitle("Capture Quote")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: .init(
            get: { captureState == .reviewing },
            set: { if !$0 { captureState = .previewing } }
        )) {
            if let image = capturedImage {
                ImageReviewView(
                    image: image,
                    qualityResult: qualityResult,
                    book: book,
                    onRetake: {
                        retakePhoto()
                    },
                    onConfirm: {
                        confirmPhoto(image)
                    }
                )
            }
        }
        .fullScreenCover(isPresented: .init(
            get: { captureState == .processing },
            set: { _ in }
        )) {
            processingView
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showExtractionReview) {
            if let session = capturedSession {
                ExtractionReviewView(
                    session: session,
                    book: book,
                    onComplete: {
                        showExtractionReview = false
                        finalizeCaptureFlow()
                    }
                )
            }
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cameraService.cleanup()
        }
    }

    // MARK: - Camera Content

    @ViewBuilder
    private var cameraContent: some View {
        if cameraService.isAuthorized {
            CameraPreviewView(cameraService: cameraService)
                .ignoresSafeArea()
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.cameraPreview)
        } else {
            CameraPermissionView()
                .environment(cameraPermission)
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.permissionPrompt)
        }
    }

    // MARK: - Quality Overlay

    @ViewBuilder
    private var qualityOverlayContent: some View {
        VStack {
            if let result = qualityResult {
                MinimalQualityOverlay(qualityResult: result)
                    .padding(.top, Spacing.lg)
            } else if isAnalyzingQuality {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Analyzing...")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
                .padding(Spacing.sm)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.top, Spacing.lg)
            }
            Spacer()
        }
    }

    // MARK: - Capture Controls

    private var captureControls: some View {
        VStack {
            Spacer()

            VStack(spacing: Spacing.md) {
                HStack(alignment: .center, spacing: Spacing.xl) {
                    // Toggle quality overlay
                    Button {
                        withAnimation(.snappy) {
                            showQualityOverlay.toggle()
                        }
                    } label: {
                        Image(systemName: showQualityOverlay ? "eye.fill" : "eye.slash")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(Spacing.md)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    // Capture button
                    Button {
                        capturePhoto()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 72, height: 72)

                            Circle()
                                .stroke(.white.opacity(0.5), lineWidth: 4)
                                .frame(width: 82, height: 82)
                        }
                    }
                    .disabled(!cameraService.isSessionRunning)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Capture.captureButton)

                    // Spacer for balance
                    Color.clear
                        .frame(width: 44, height: 44)
                }

                if UITestConfiguration.isUITesting && !UITestConfiguration.isAppStoreMediaMode {
                    Button("Use Test Image") {
                        captureTestImage()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Capture.testImageButton)
                }
            }
            .padding(Spacing.lg)
            .glassFloating(cornerRadius: CornerRadius.xl)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
    }

    private var topHud: some View {
        VStack {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text("Capture a marked page")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "text.quote")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .glassFloating(cornerRadius: CornerRadius.lg)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)

            Spacer()
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.brand)

            Text("Processing image...")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            Text("Extracting marked passages")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.cancelButton)
        }

        ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
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
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // MARK: - Capture Actions

    private func capturePhoto() {
        Task {
            do {
                HapticManager.medium()

                let image = try await cameraService.capturePhoto()
                let cropped = cameraService.cropToPreviewVisibleArea(image)
                let autoCropped = await cameraService.autoCropDocument(cropped)
                await handleCapturedImage(autoCropped)

            } catch {
                errorMessage = error.localizedDescription
                showError = true
                HapticManager.error()
            }
        }
    }

    private func captureTestImage() {
        let image = MockCameraImages.getTestImage(
            multipleQuotes: false,
            lowConfidence: false,
            index: 0
        )
        Task {
            await handleCapturedImage(image)
        }
    }

    @MainActor
    private func handleCapturedImage(_ image: UIImage) async {
        capturedImage = image

        // Analyze quality
        isAnalyzingQuality = true
        do {
            let result = try await qualityAnalyzer.analyze(image: image)
            qualityResult = result
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isAnalyzingQuality = false

        // Show review sheet
        captureState = .reviewing
    }

    private func retakePhoto() {
        capturedImage = nil
        qualityResult = nil
        captureState = .previewing
        cameraService.clearCapturedImage()
    }

    private func confirmPhoto(_ image: UIImage) {
        captureState = .processing

        Task {
            do {
                // Preprocess image
                let processed = try ImagePreprocessor.processForQuoteExtraction(image)

                // Create a single-page capture session
                let session = CaptureSession(book: book)
                modelContext.insert(session)

                // Create page capture
                try PageCapture.ensureDirectory(for: session.id)
                let imagePath = PageCapture.generateImagePath(sessionId: session.id)
                try PageCapture.saveImage(processed.data, to: imagePath)

                let pageCapture = PageCapture(imagePath: imagePath, session: session)
                pageCapture.orderIndex = 0

                // Generate and save thumbnail
                if let thumbnailData = try? ImagePreprocessor.createThumbnail(image) {
                    pageCapture.thumbnailData = thumbnailData
                }

                modelContext.insert(pageCapture)
                session.captures.append(pageCapture)
                session.totalPages = 1

                if UITestConfiguration.isUITesting {
                    seedExtractionForUITest(pageCapture: pageCapture, session: session)
                } else {
                    // Mark session as ready for processing
                    session.finishCapturing()
                }

                try modelContext.save()

                await MainActor.run {
                    captureState = .completed(session: session)
                    capturedSession = session
                    showExtractionReview = true
                }

            } catch {
                await MainActor.run {
                    captureState = .previewing
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func finalizeCaptureFlow() {
        if let onComplete {
            onComplete()
        } else {
            retakePhoto()
        }
    }

    private func seedExtractionForUITest(pageCapture: PageCapture, session: CaptureSession) {
        let quotes = [
            ExtractedQuoteData(
                text: "Test quote extracted for UI testing.",
                pageNumber: 12,
                marginNote: nil,
                markingType: "underline",
                confidence: 0.92
            )
        ]

        pageCapture.storeExtractedQuotes(quotes)
        pageCapture.completeProcessing(
            quoteCount: quotes.count,
            avgConfidence: quotes.compactMap { $0.confidence }.first,
            pageNumber: quotes.first?.pageNumber
        )

        session.status = .processing
        session.recordSuccess()
    }
}

// MARK: - Capture State

extension QuoteCaptureView {
    enum CaptureState: Equatable {
        case previewing
        case reviewing
        case processing
        case completed(session: CaptureSession)

        static func == (lhs: CaptureState, rhs: CaptureState) -> Bool {
            switch (lhs, rhs) {
            case (.previewing, .previewing),
                 (.reviewing, .reviewing),
                 (.processing, .processing):
                return true
            case (.completed(let a), .completed(let b)):
                return a.id == b.id
            default:
                return false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let container: ModelContainer? = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try? ModelContainer(for: Book.self, configurations: config)
    }()

    if let container {
        let book: Book = {
            let book = Book(title: "Test Book", author: "Test Author")
            container.mainContext.insert(book)
            return book
        }()

        QuoteCaptureView(book: book)
            .modelContainer(container)
    } else {
        Text("Preview unavailable")
            .foregroundStyle(.secondary)
    }
}
