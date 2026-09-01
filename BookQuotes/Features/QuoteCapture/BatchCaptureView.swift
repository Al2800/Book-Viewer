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
    @StateObject private var milestoneManager = MilestoneManager()
    private let cameraFramingProfile = CameraFramingProfile.quotePage

    // MARK: - Initialization

    init(
        book: Book,
        session: CaptureSession? = nil,
        hidesHeaderBar: Bool = false,
        hidesTabBar: Bool = true,
        onComplete: @escaping (CaptureSession) -> Void,
        onCancel: @escaping () -> Void
    ) {
        let activeSession = session ?? CaptureSession(book: book)
        activeSession.resumeCapturing()
        self.book = book
        self.hidesHeaderBar = hidesHeaderBar
        self.hidesTabBar = hidesTabBar
        self.onComplete = onComplete
        self.onCancel = onCancel
        self._session = State(initialValue: activeSession)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            cameraPreviewLayer

            VStack(spacing: 0) {
                if !hidesHeaderBar {
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

    @ViewBuilder
    private var sessionHeader: some View {
        CaptureHeaderBar(
            title: book.title,
            subtitle: "\(session.totalPages) page\(session.totalPages == 1 ? "" : "s") in session",
            subtitleAccessibilityIdentifier: AccessibilityIdentifiers.Capture.pageCounter,
            onCancel: cancelBatchCapture
        ) {
            Button {
                _ = lifecycleState.requestFinish(pageCount: session.totalPages)
            } label: {
                Text("Done")
                    .font(.subheadline.weight(.semibold))
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
            if let statusPill = batchStatusPill {
                statusPill
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if !session.captures.isEmpty {
                thumbnailStrip
            }

            HStack(spacing: Spacing.xl) {
                CaptureFlashButton(
                    flashMode: cameraService.flashMode,
                    isAvailable: cameraService.isFlashAvailable
                ) {
                    cameraService.cycleFlashMode()
                }

                CaptureButton(isProcessing: lifecycleState.isCapturing) {
                    await captureCurrentFrame()
                }

                Button {
                    do {
                        try cameraService.switchCamera()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                        HapticManager.error()
                    }
                } label: {
                    Image(systemName: "camera.rotate")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.black.opacity(0.35), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Switch camera")
            }
            .padding(.bottom, Spacing.xl)

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

    // MARK: - Thumbnail Strip

    @ViewBuilder
    private var thumbnailStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Spacing.sm) {
                    ForEach(session.captures) { capture in
                        Button {
                            selectedCapture = capture
                            lifecycleState.showsCaptureDetail = true
                        } label: {
                            ThumbnailView(capture: capture)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.thumbnail)
                        .accessibilityLabel("Captured page \(capture.orderIndex + 1)")
                        .id(capture.id)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .frame(height: 70)
            .cameraChrome(cornerRadius: CornerRadius.lg)
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.thumbnailStrip)
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
            .onChange(of: session.captures.count) { _, _ in
                if let lastCapture = session.captures.last {
                    withAnimation(.smoothSpring) {
                        proxy.scrollTo(lastCapture.id, anchor: .trailing)
                    }
                }
            }
        }
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

        HapticManager.impact(.medium)

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

    private var batchStatusPill: CaptureStatusPill? {
        if !cameraService.detectedBoundingBoxes.isEmpty {
            let count = cameraService.detectedBoundingBoxes.count
            return CaptureStatusPill(
                systemImage: "text.viewfinder",
                text: "Text detected • \(count) region\(count == 1 ? "" : "s")",
                tint: Color.gildedAccent
            )
        }

        if let quality = currentQuality, !quality.isAcceptable {
            return CaptureStatusPill(
                systemImage: "exclamationmark.triangle.fill",
                text: quality.issues.first?.advice ?? "Adjust framing before the next page",
                tint: Color.warning
            )
        }

        return CaptureStatusPill(
            systemImage: "doc.on.doc",
            text: lifecycleState.statusText(pageCount: session.totalPages)
        )
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
