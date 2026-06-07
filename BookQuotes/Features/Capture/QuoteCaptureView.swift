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

    /// Cancellation handler for callers embedding the capture flow in custom navigation.
    var onCancel: (() -> Void)?

    // MARK: - State

    @State private var cameraService = CameraService()
    @State private var qualityAnalyzer = ImageQualityAnalyzer(configuration: .lenient)
    @State private var cameraPermission = CameraPermissionService()
    @State private var captureState: CaptureState = .previewing
    @State private var capturedImage: UIImage?
    @State private var qualityResult: ImageQualityAnalyzer.QualityResult?
    @State private var isAnalyzingQuality = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showExtractionReview = false
    @State private var capturedSession: CaptureSession?
    private let cameraFramingProfile = CameraFramingProfile.quotePage

    // MARK: - Body

    var body: some View {
        ZStack {
            // Camera preview / captured image
            cameraContent

            if captureState == .previewing {
                VStack(spacing: 0) {
                    CaptureHeaderBar(
                        title: book.title,
                        subtitle: "Single page capture",
                        onCancel: cancelCapture
                    )

                    Spacer()
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        // The system tab bar can overlap full-screen camera controls on newer iOS versions.
        // Hide it during capture so the shutter controls are always visible.
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            if captureState == .previewing {
                bottomCaptureControls
            }
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
        .fullScreenCover(isPresented: $showExtractionReview, onDismiss: {
            // Always reset to previewing when the review flow is dismissed.
            // This prevents returning to a camera preview with no shutter controls.
            retakePhoto()
        }) {
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
            CameraPreviewView(cameraService: cameraService, framingProfile: cameraFramingProfile)
                .ignoresSafeArea()
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.cameraPreview)
        } else {
            CameraPermissionView()
                .environment(cameraPermission)
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.permissionPrompt)
        }
    }

    // MARK: - Capture Controls

    private var bottomCaptureControls: some View {
        CaptureControlTray {
            if let statusPill = qualityStatusPill {
                statusPill
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            HStack {
                Spacer()

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

                Spacer()
            }

            if UITestConfiguration.isUITesting && !UITestConfiguration.isAppStoreMediaMode {
                Button("Use Test Image") {
                    captureTestImage()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.testImageButton)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
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

    private var qualityStatusPill: CaptureStatusPill? {
        if isAnalyzingQuality {
            return CaptureStatusPill(
                systemImage: "viewfinder",
                text: "Analyzing image…"
            )
        }

        guard let result = qualityResult else {
            return CaptureStatusPill(
                systemImage: "text.viewfinder",
                text: "Center one marked passage and capture the page"
            )
        }

        if result.isAcceptable {
            return CaptureStatusPill(
                systemImage: "checkmark.circle.fill",
                text: "Ready to capture",
                tint: .white
            )
        }

        let issueText = result.issues.isEmpty ? "Adjust framing" : result.issues[0].advice
        return CaptureStatusPill(
            systemImage: "exclamationmark.triangle.fill",
            text: issueText,
            tint: Color.warning
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
                let previewSize = cameraService.currentPreviewSizeForCropping()

                // Crop + document detection can be expensive. Do it off the MainActor so capture doesn't freeze.
                let prepared = await Task.detached(priority: .userInitiated) { () -> UIImage in
                    var working = image
                    if cameraFramingProfile.captureCropBehavior == .aspectFillVisibleArea,
                       let previewSize {
                        working = (try? ImagePreprocessor.cropToAspectFillPreview(working, previewSize: previewSize)) ?? working
                    }
                    return await ImagePreprocessor.autoCropDocument(working)
                }.value

                await handleCapturedImage(prepared)

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

    private func handleCapturedImage(_ image: UIImage) async {
        await MainActor.run {
            capturedImage = image
            isAnalyzingQuality = true
            qualityResult = nil
        }

        // Vision-based analysis can be expensive. Keep it off the MainActor to prevent the capture UI from freezing.
        do {
            let result = try await Task.detached(priority: .userInitiated) {
                let analyzer = ImageQualityAnalyzer(configuration: .lenient)
                return try await analyzer.analyze(image: image)
            }.value

            await MainActor.run {
                qualityResult = result
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }

        await MainActor.run {
            isAnalyzingQuality = false
            // Show review sheet
            captureState = .reviewing
        }
    }

    private func retakePhoto() {
        capturedImage = nil
        qualityResult = nil
        captureState = .previewing
        cameraService.clearCapturedImage()
    }

    @MainActor
    private func confirmPhoto(_ image: UIImage) {
        captureState = .processing

        Task {
            do {
                // Preprocessing + disk IO can be expensive and should not run on the main actor.
                // Generate a stable session id up front so we can write files before inserting SwiftData models.
                let sessionID = UUID()

                let (imagePath, thumbnailData) = try await withCheckedThrowingContinuation { continuation in
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            let processed = try ImagePreprocessor.processForQuoteExtraction(image)

                            try PageCapture.ensureDirectory(for: sessionID)
                            let imagePath = PageCapture.generateImagePath(sessionId: sessionID)
                            try PageCapture.saveImage(processed.data, to: imagePath)

                            let thumbnailData = try? ImagePreprocessor.createThumbnail(image)
                            continuation.resume(returning: (imagePath, thumbnailData))
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }

                // SwiftData work must stay on the main actor.
                let session = CaptureSession(book: book)
                session.id = sessionID
                modelContext.insert(session)

                let pageCapture = PageCapture(imagePath: imagePath, session: session)
                pageCapture.orderIndex = 0
                pageCapture.thumbnailData = thumbnailData

                modelContext.insert(pageCapture)
                session.addCapture(pageCapture)

                if UITestConfiguration.isUITesting {
                    seedExtractionForUITest(pageCapture: pageCapture, session: session)
                } else {
                    // Mark session as ready for processing
                    session.finishCapturing()
                }

                try modelContext.save()

                captureState = .completed(session: session)
                capturedSession = session
                showExtractionReview = true

            } catch {
                captureState = .previewing
                errorMessage = error.localizedDescription
                showError = true
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

    private func cancelCapture() {
        if let onCancel {
            onCancel()
        } else {
            dismiss()
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
