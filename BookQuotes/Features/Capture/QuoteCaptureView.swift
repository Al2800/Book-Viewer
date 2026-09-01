import SwiftUI
import AVFoundation
import SwiftData

// MARK: - Quote Capture View

/// Single-page quote capture view with camera preview, capture, and review flow.
struct QuoteCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let book: Book
    var hidesHeaderBar: Bool = false
    var hidesTabBar: Bool = true
    var onComplete: (() -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - State

    @State private var cameraService = CameraService()
    @State private var cameraPermission = CameraPermissionService()
    @State private var captureState: CaptureState = .previewing
    @State private var capturedImage: UIImage?
    @State private var qualityResult: ImageQualityAnalyzer.QualityResult?
    @State private var isQualityFeedbackUnavailable = false
    @State private var isAnalyzingQuality = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var capturedSession: CaptureSession?
    private let cameraFramingProfile = CameraFramingProfile.quotePage
    private let imageProcessor = QuoteCaptureImageProcessor()

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            cameraContent

            if captureState == .qualityChecking {
                qualityCheckingOverlay
            }

            if captureState == .processing {
                processingView
            }

            if captureState == .previewing && !hidesHeaderBar {
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

            if captureState == .previewing && cameraService.isAuthorized {
                VStack(spacing: 0) {
                    Spacer()
                    bottomCaptureControls
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(hidesTabBar ? .hidden : .automatic, for: .tabBar)
        .sheet(isPresented: .init(
            get: { captureState == .reviewing },
            set: { isPresented in
                // Confirming a photo advances to processing before the review sheet closes.
                // Do not let the sheet binding overwrite that state with previewing.
                if !isPresented, captureState == .reviewing {
                    captureState = .previewing
                }
            }
        )) {
            if let image = capturedImage {
                ImageReviewView(
                    image: image,
                    qualityResult: qualityResult,
                    isQualityFeedbackUnavailable: isQualityFeedbackUnavailable,
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(item: $capturedSession, onDismiss: {
            // Cancellation and completion both return the embedded camera to a usable state.
            retakePhoto()
        }) { session in
            ExtractionReviewView(
                session: session,
                book: book,
                onComplete: {
                    capturedSession = nil
                    finalizeCaptureFlow()
                }
            )
        }
        .onAppear {
            cameraPermission.checkStatus()
            setupCamera()
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhase(phase)
        }
        .onDisappear {
            cameraService.cleanup()
        }
    }

    // MARK: - Camera Content

    @ViewBuilder
    private var cameraContent: some View {
        if captureState == .qualityChecking, let capturedImage {
            Color.black
                .ignoresSafeArea()
                .overlay {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
        } else if cameraService.isAuthorized && cameraService.isSessionConfigured {
            CameraPreviewViewWithFocus(cameraService: cameraService, framingProfile: cameraFramingProfile)
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

    private var qualityCheckingOverlay: some View {
        VStack(spacing: Spacing.sm) {
            ProgressView()
                .tint(.white)

            Text("Photo captured")
                .font(.headline)

            Text("Checking focus and lighting")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .foregroundStyle(.white)
        .padding(Spacing.lg)
        .cameraChrome(cornerRadius: CornerRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Photo captured. Checking focus and lighting.")
    }

    // MARK: - Capture Controls

    private var bottomCaptureControls: some View {
        CaptureControlTray {
            if let statusPill = qualityStatusPill {
                statusPill
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            HStack {
                CaptureFlashButton(
                    flashMode: cameraService.flashMode,
                    isAvailable: cameraService.isFlashAvailable
                ) {
                    cameraService.cycleFlashMode()
                }

                Spacer()

                CaptureButton(isProcessing: !cameraService.isSessionRunning || cameraService.isCapturing) {
                    capturePhoto()
                }

                Spacer()

                Color.clear
                    .frame(width: 50, height: 50)
                    .accessibilityHidden(true)
            }

            if UITestConfiguration.isUITesting && !UITestConfiguration.isAppStoreMediaMode {
                Button("Use Test Image") {
                    captureTestImage()
                }
                .buttonStyle(.primaryCompact)
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.testImageButton)
            }
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text("Processing image...")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Preparing the page for quote extraction")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }

    private var qualityStatusPill: CaptureStatusPill? {
        if isAnalyzingQuality {
            return CaptureStatusPill(
                systemImage: "viewfinder",
                text: "Analyzing image…"
            )
        }

        if !cameraService.detectedBoundingBoxes.isEmpty {
            let count = cameraService.detectedBoundingBoxes.count
            return CaptureStatusPill(
                systemImage: "text.viewfinder",
                text: "Text detected • \(count) region\(count == 1 ? "" : "s")",
                tint: Color.gildedAccent
            )
        }

        guard let result = qualityResult else {
            return CaptureStatusPill(
                systemImage: "text.viewfinder",
                text: cameraFramingProfile.guidanceText
            )
        }

        if result.isAcceptable {
            return CaptureStatusPill(
                systemImage: "checkmark.circle.fill",
                text: "Image quality looks good",
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

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            cameraPermission.onAppBecameActive()
            cameraService.checkAuthorization()

            guard cameraPermission.isAuthorized, cameraService.isAuthorized else { return }
            if cameraService.isSessionConfigured {
                cameraService.startSession()
            } else {
                setupCamera()
            }

        case .background:
            cameraService.stopSession()

        case .inactive:
            break

        @unknown default:
            break
        }
    }

    // MARK: - Capture Actions

    private func capturePhoto() {
        Task {
            do {
                HapticManager.medium()

                let image = try await cameraService.capturePhoto()
                HapticManager.captureSuccess()
                let previewSize = cameraService.currentPreviewSizeForCropping()

                await handleCapturedImage(image, previewSize: previewSize)
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
            lowConfidence: UITestConfiguration.shouldMockLowConfidence,
            index: 0
        )
        HapticManager.captureSuccess()
        Task {
            await handleCapturedImage(image)
        }
    }

    private func handleCapturedImage(_ image: UIImage, previewSize: CGSize? = nil) async {
        await MainActor.run {
            capturedImage = image
            isAnalyzingQuality = true
            qualityResult = nil
            isQualityFeedbackUnavailable = false
            captureState = .qualityChecking
        }

        let result = await imageProcessor.process(
            image,
            previewSize: previewSize,
            framingProfile: cameraFramingProfile
        )

        await MainActor.run {
            capturedImage = result.image
            qualityResult = result.qualityResult
            isQualityFeedbackUnavailable = result.qualityError != nil

            isAnalyzingQuality = false
            captureState = .reviewing
        }
    }

    private func retakePhoto() {
        capturedImage = nil
        qualityResult = nil
        isQualityFeedbackUnavailable = false
        captureState = .previewing
        cameraService.clearCapturedImage()
    }

    @MainActor
    private func confirmPhoto(_ image: UIImage) {
        captureState = .processing

        Task {
            do {
                let store = QuoteCaptureSessionStore(modelContext: modelContext)
                let session = try await store.createSession(
                    for: book,
                    image: image,
                    seedForUITest: UITestConfiguration.isUITesting
                )

                captureState = .completed(session: session)
                capturedSession = session
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
}

// MARK: - Capture State

extension QuoteCaptureView {
    enum CaptureState: Equatable {
        case previewing
        case qualityChecking
        case reviewing
        case processing
        case completed(session: CaptureSession)

        static func == (lhs: CaptureState, rhs: CaptureState) -> Bool {
            switch (lhs, rhs) {
            case (.previewing, .previewing),
                 (.qualityChecking, .qualityChecking),
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
