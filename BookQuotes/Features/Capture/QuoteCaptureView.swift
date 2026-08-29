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
            // Camera preview / captured image
            cameraContent

            if captureState == .qualityChecking {
                qualityCheckingOverlay
            }

            if captureState == .processing {
                processingView
            }

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
            if captureState == .previewing && cameraService.isAuthorized {
                bottomCaptureControls
            }
        }
        .sheet(isPresented: .init(
            get: { captureState == .reviewing },
            set: { newValue in
                if !newValue, captureState == .reviewing {
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
            // Always reset to previewing when the review flow is dismissed.
            // This prevents returning to a camera preview with no shutter controls.
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
        .onDisappear {
            cameraService.cleanup()
        }
        .cameraSessionHandlesScenePhase(cameraService)
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
                .disabled(!cameraService.isSessionRunning || cameraService.isCapturing)
                .accessibilityLabel("Take photo")
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.captureButton)

                Spacer()

                Color.clear
                    .frame(width: 50, height: 50)
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
                text: cameraFramingProfile.guidanceText
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
            // Show review sheet
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
