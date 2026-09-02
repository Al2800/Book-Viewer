import SwiftUI
import SwiftData

// MARK: - Batch Capture View

/// Multi-page batch capture interface with thumbnail strip and session controls.
/// Supports capturing 20+ pages efficiently with real-time quality feedback.
struct BatchCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let book: Book
    var hidesHeaderBar: Bool = false
    var hidesTabBar: Bool = true
    var onSwitchBook: (() -> Void)? = nil
    let onComplete: (CaptureSession) -> Void
    let onCancel: () -> Void

    @State private var session: CaptureSession
    @State private var cameraService = CameraService()
    @State private var cameraPermission = CameraPermissionService()
    @State private var currentQuality: ImageQualityAnalyzer.QualityResult?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var lifecycleState = BatchCaptureLifecycleState()
    @State private var selectedCapture: PageCapture?
    @State private var retakeSuggestion = false
    @State private var retakeClearTask: Task<Void, Never>?
    @StateObject private var milestoneManager = MilestoneManager()
    private let cameraFramingProfile = CameraFramingProfile.quotePage

    // MARK: - Initialization

    init(
        book: Book,
        session: CaptureSession? = nil,
        hidesHeaderBar: Bool = false,
        hidesTabBar: Bool = true,
        onSwitchBook: (() -> Void)? = nil,
        onComplete: @escaping (CaptureSession) -> Void,
        onCancel: @escaping () -> Void
    ) {
        let activeSession = session ?? CaptureSession(book: book)
        activeSession.resumeCapturing()
        self.book = book
        self.hidesHeaderBar = hidesHeaderBar
        self.hidesTabBar = hidesTabBar
        self.onSwitchBook = onSwitchBook
        self.onComplete = onComplete
        self.onCancel = onCancel
        self._session = State(initialValue: activeSession)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            cameraPreviewLayer

            VStack(spacing: 0) {
                if hidesHeaderBar {
                    batchHUDChrome
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.sm)
                } else {
                    sessionHeader
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.sm)
                }

                Spacer()

                if cameraService.isAuthorized {
                    bottomControls
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .statusBarHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(hidesTabBar ? .hidden : .automatic, for: .tabBar)
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
        .alert("Capture Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $lifecycleState.showsCaptureDetail) {
            if let capture = selectedCapture {
                CaptureDetailSheet(capture: capture, session: session) {
                    removeCapture(capture)
                }
            }
        }
        .confirmationDialog(
            "Finish Capture Session?",
            isPresented: $lifecycleState.showsFinishConfirmation,
            titleVisibility: .visible
        ) {
            Button("Process \(session.totalPages) Pages") {
                finishAndProcess()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.processBatchButton)
            Button("Save Draft") {
                saveDraft()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.saveDraftButton)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You captured \(session.totalPages) pages. Would you like to process them now or save as draft?")
        }
        .milestoneCelebration(manager: milestoneManager)
    }

    // MARK: - Camera Preview

    @ViewBuilder
    private var cameraPreviewLayer: some View {
        ZStack {
            if !cameraService.isAuthorized {
                CameraPermissionView()
                    .environment(cameraPermission)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Capture.permissionPrompt)
            } else if cameraService.isSessionConfigured {
                CameraPreviewViewWithFocus(cameraService: cameraService, framingProfile: cameraFramingProfile)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }

            if cameraService.isAuthorized && !cameraService.isSessionRunning {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                ProgressView()
                    .tint(.white)
            }
        }
    }

    // MARK: - Session Header

    private var batchHUDChrome: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            ActiveBookHUDView(
                book: book,
                onSwitchBook: {
                    onSwitchBook?()
                },
                onClose: cancelBatchCapture
            )

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                HStack(alignment: .top, spacing: Spacing.xs) {
                    CaptureModeMenuButton(
                        currentMode: .batch,
                        onSelectSingle: cancelBatchCapture
                    )

                    Button {
                        finishAndProcess()
                    } label: {
                    Text("Done")
                        .font(.uiLabel)
                        .foregroundStyle(lifecycleState.canFinish(pageCount: session.totalPages) ? Color.gildedAccent : Color.white.opacity(0.45))
                        .frame(minWidth: 44, minHeight: 44)
                        .padding(.horizontal, Spacing.md)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.62))
                                .overlay {
                                    Capsule()
                                        .stroke(Color.white.opacity(0.22), lineWidth: Stroke.hairline.width)
                                }
                        )
                }
                .buttonStyle(.plain)
                .disabled(!lifecycleState.canFinish(pageCount: session.totalPages))
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.doneButton)
                }

                Text("\(session.totalPages) page\(session.totalPages == 1 ? "" : "s") in session")
                    .font(.uiCaption)
                    .foregroundStyle(.white.opacity(0.78))
                    .accessibilityIdentifier(AccessibilityIdentifiers.Capture.pageCounter)
            }
        }
    }

    @ViewBuilder
    private var sessionHeader: some View {
        CaptureHeaderBar(
            title: book.title,
            subtitle: "\(session.totalPages) page\(session.totalPages == 1 ? "" : "s") in session",
            subtitleAccessibilityIdentifier: AccessibilityIdentifiers.Capture.pageCounter,
            onCancel: cancelBatchCapture
        ) {
            Button {
                finishAndProcess()
            } label: {
                Text("Done")
                    .font(.uiLabel)
                    .foregroundStyle(lifecycleState.canFinish(pageCount: session.totalPages) ? Color.accent : Color.white.opacity(0.45))
            }
            .buttonStyle(.plain)
            .disabled(!lifecycleState.canFinish(pageCount: session.totalPages))
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.doneButton)
        }
    }

    // MARK: - Bottom Controls

    @ViewBuilder
    private var bottomControls: some View {
        CaptureControlTray {
            if let status = batchTrayStatus {
                batchTrayPill(status)
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

                CaptureButton(isProcessing: lifecycleState.isCapturing || !cameraService.isSessionRunning || cameraService.isCapturing) {
                    await captureCurrentFrame()
                }

                Spacer()

                batchPhotoStripSlot
            }

            if UITestConfiguration.isUITesting && !UITestConfiguration.isAppStoreMediaMode {
                Button("Use Test Image") {
                    Task {
                        await captureCurrentFrame()
                    }
                }
                .buttonStyle(.primaryCompact)
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.testImageButton)
                .disabled(lifecycleState.isCapturing)
            }
        }
    }

    @ViewBuilder
    private var batchPhotoStripSlot: some View {
        if let lastCapture = session.captures.last {
            Button {
                selectedCapture = lastCapture
                lifecycleState.showsCaptureDetail = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Group {
                        if let thumbnail = lastCapture.loadThumbnail() ?? lastCapture.loadFullImage() {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.white.opacity(0.12)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )

                    Text("\(session.totalPages)")
                        .font(.uiBadge)
                        .foregroundStyle(Color.darkLinen)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.gildedAccent, in: Capsule())
                        .offset(x: 6, y: -6)
                }
            }
            .frame(width: 50, height: 50)
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.photoStrip)
            .accessibilityLabel("Last captured page, \(session.totalPages) in session")
        } else {
            Color.clear
                .frame(width: 50, height: 50)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func batchTrayPill(_ status: QuoteCaptureView.CaptureTrayStatus) -> some View {
        switch status {
        case .framing(let text):
            CaptureStatusPill(systemImage: "text.viewfinder", text: text)
        case .readingPage:
            CaptureStatusPill(systemImage: "viewfinder", text: "Reading page…")
        case .retake:
            Button {
                HapticManager.light()
                discardLastRetakeFrame()
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

    private var batchTrayStatus: QuoteCaptureView.CaptureTrayStatus? {
        if retakeSuggestion {
            return .retake
        }
        if lifecycleState.isCapturing {
            return .readingPage
        }
        return .framing(cameraFramingProfile.guidanceText)
    }

    // MARK: - Actions

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

    @MainActor
    private func captureCurrentFrame() async {
        guard !lifecycleState.isCapturing else { return }

        lifecycleState.isCapturing = true
        defer { lifecycleState.isCapturing = false }

        do {
            let image = try await cameraService.capturePhoto()
            let pageStore = BatchCapturePageStore(modelContext: modelContext)
            let result = try await pageStore.appendCapture(
                to: session,
                image: image,
                previewSize: cameraService.currentPreviewSizeForCropping(),
                cropBehavior: cameraFramingProfile.captureCropBehavior
            )
            currentQuality = result.quality
            cameraService.clearCapturedImage()

            HapticManager.captureSuccess()
            checkMilestone(count: session.totalPages)

            if let quality = result.quality,
               QuoteCaptureView.shouldSuggestRetake(isAcceptable: quality.isAcceptable, overallScore: quality.overallScore) {
                presentRetakeSuggestion()
            } else {
                retakeSuggestion = false
                retakeClearTask?.cancel()
            }
        } catch {
            HapticManager.error()
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func removeCapture(_ capture: PageCapture) {
        session.captures.removeAll { $0.id == capture.id }
        session.totalPages = max(0, session.totalPages - 1)
        capture.deleteImageFile()
        modelContext.delete(capture)
        HapticManager.impact(.light)
    }

    private func checkMilestone(count: Int) {
        milestoneManager.checkPageMilestone(pageCount: count)
    }

    private func finishAndProcess() {
        session.finishCapturing()
        modelContext.insert(session)
        try? modelContext.save()
        onComplete(session)
    }

    private func saveDraft() {
        session.finishCapturing()
        modelContext.insert(session)
        try? modelContext.save()
        HapticManager.success()
        onCancel()
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

    private func discardLastRetakeFrame() {
        retakeClearTask?.cancel()
        retakeSuggestion = false
        currentQuality = nil
        if let lastCapture = session.captures.last {
            removeCapture(lastCapture)
        }
        cameraService.clearCapturedImage()
    }

    private func cancelBatchCapture() {
        switch lifecycleState.requestCancel(pageCount: session.totalPages) {
        case .cancel:
            onCancel()
        case .showFinishConfirmation:
            break
        case .none, .complete, .showOfflineConfirmation:
            break
        }
    }
}
