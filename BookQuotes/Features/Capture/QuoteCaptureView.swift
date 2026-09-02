import SwiftUI
import AVFoundation
import SwiftData

// MARK: - Quote Capture View

/// Single-page quote capture view with camera preview, capture, and review flow.
struct QuoteCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
    @State private var lastStripImage: UIImage?
    @State private var flyInImage: UIImage?
    @State private var flyInProgress: CGFloat = 0
    @State private var qualityResult: ImageQualityAnalyzer.QualityResult?
    @State private var isQualityFeedbackUnavailable = false
    @State private var retakeSuggestion = false
    @State private var retakeClearTask: Task<Void, Never>?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var capturedSession: CaptureSession?
    @State private var showPassagesSheet = false
    private let cameraFramingProfile = CameraFramingProfile.quotePage
    private let imageProcessor = QuoteCaptureImageProcessor()

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            cameraContent

            if let flyInImage {
                Image(uiImage: flyInImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .scaleEffect(reduceMotion ? 1 : (1 - (0.88 * flyInProgress)))
                    .opacity(1 - flyInProgress)
                    .allowsHitTesting(false)
            }

            if cameraService.isAuthorized {
                VStack(spacing: 0) {
                    Spacer()
                    bottomCaptureControls
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .statusBarHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(hidesTabBar ? .hidden : .automatic, for: .tabBar)
        .sheet(isPresented: $showPassagesSheet, onDismiss: {
            retakePhoto()
        }) {
            if let capturedSession {
                ExtractionReviewView(
                    session: capturedSession,
                    book: book,
                    onComplete: {
                        showPassagesSheet = false
                        self.capturedSession = nil
                        lastStripImage = nil
                        finalizeCaptureFlow()
                    }
                )
                .presentationDetents([.large])
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            cameraPermission.checkStatus()
            setupCamera()
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhase(phase)
        }
        .onDisappear {
            retakeClearTask?.cancel()
            cameraService.cleanup()
        }
    }

    // MARK: - Camera Content

    @ViewBuilder
    private var cameraContent: some View {
        if cameraService.isAuthorized && cameraService.isSessionConfigured {
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

    // MARK: - Capture Controls

    private var bottomCaptureControls: some View {
        CaptureControlTray {
            if let status = trayStatus {
                trayPill(status)
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

                CaptureButton(isProcessing: captureState == .processing || !cameraService.isSessionRunning || cameraService.isCapturing) {
                    capturePhoto()
                }

                Spacer()

                photoStripSlot
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

    @ViewBuilder
    private var photoStripSlot: some View {
        if let lastStripImage {
            Button {
                guard capturedSession != nil else { return }
                showPassagesSheet = true
            } label: {
                Image(uiImage: lastStripImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
            }
            .frame(width: 50, height: 50)
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.photoStrip)
            .accessibilityLabel("Last captured page")
        } else {
            Color.clear
                .frame(width: 50, height: 50)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func trayPill(_ status: CaptureTrayStatus) -> some View {
        switch status {
        case .framing(let text):
            CaptureStatusPill(systemImage: "text.viewfinder", text: text)
        case .readingPage:
            CaptureStatusPill(systemImage: "viewfinder", text: "Reading page…")
        case .retake:
            Button {
                HapticManager.light()
                discardRetakeFrame()
            } label: {
                CaptureStatusPill(
                    systemImage: "exclamationmark.triangle.fill",
                    text: "Too blurry to read — tap to retake",
                    tint: Color.warning
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.retakePill)
        }
    }

    private var trayStatus: CaptureTrayStatus? {
        if retakeSuggestion {
            return .retake
        }
        if captureState == .processing {
            return .readingPage
        }
        return .framing(cameraFramingProfile.guidanceText)
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
            qualityResult = nil
            isQualityFeedbackUnavailable = false
            retakeSuggestion = false
            animateCapturedFrameToStrip(image)
        }

        let result = await imageProcessor.process(
            image,
            previewSize: previewSize,
            framingProfile: cameraFramingProfile
        )

        await MainActor.run {
            capturedImage = result.image
            lastStripImage = result.image
            qualityResult = result.qualityResult
            isQualityFeedbackUnavailable = result.qualityError != nil

            if let quality = result.qualityResult,
               Self.shouldSuggestRetake(isAcceptable: quality.isAcceptable, overallScore: quality.overallScore) {
                presentRetakeSuggestion()
                return
            }

            confirmPhoto(result.image)
        }
    }

    @MainActor
    private func animateCapturedFrameToStrip(_ image: UIImage) {
        flyInImage = image
        flyInProgress = 0
        lastStripImage = image

        if reduceMotion {
            withAnimation(.easeOut(duration: 0.2)) {
                flyInProgress = 1
            }
        } else {
            withAnimation(.smoothSpring) {
                flyInProgress = 1
            }
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 220 : 400))
            flyInImage = nil
            flyInProgress = 0
        }
    }

    @MainActor
    private func presentRetakeSuggestion() {
        retakeSuggestion = true
        retakeClearTask?.cancel()
        retakeClearTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            retakeSuggestion = false
        }
    }

    private func discardRetakeFrame() {
        retakeClearTask?.cancel()
        retakeSuggestion = false
        capturedImage = nil
        qualityResult = nil
        isQualityFeedbackUnavailable = false
        if capturedSession == nil {
            lastStripImage = nil
        }
        captureState = .previewing
        cameraService.clearCapturedImage()
    }

    private func retakePhoto() {
        retakeClearTask?.cancel()
        capturedImage = nil
        qualityResult = nil
        isQualityFeedbackUnavailable = false
        retakeSuggestion = false
        captureState = .previewing
        cameraService.clearCapturedImage()
    }

    @MainActor
    private func confirmPhoto(_ image: UIImage) {
        captureState = .processing
        retakeSuggestion = false

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
                showPassagesSheet = true
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
        case processing
        case completed(session: CaptureSession)

        static func == (lhs: CaptureState, rhs: CaptureState) -> Bool {
            switch (lhs, rhs) {
            case (.previewing, .previewing),
                 (.processing, .processing):
                return true
            case (.completed(let a), .completed(let b)):
                return a.id == b.id
            default:
                return false
            }
        }
    }

    enum CaptureTrayStatus: Equatable {
        case framing(String)
        case readingPage
        case retake
    }

    static func shouldSuggestRetake(isAcceptable: Bool, overallScore: Double) -> Bool {
        !isAcceptable && overallScore < 0.4
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
