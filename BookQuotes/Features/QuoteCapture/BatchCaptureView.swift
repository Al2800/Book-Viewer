import SwiftUI
import SwiftData

// MARK: - Batch Capture View

/// Multi-page batch capture interface with thumbnail strip and session controls.
/// Supports capturing 20+ pages efficiently with real-time quality feedback.
/// Integrates with CaptureQueueManager for offline processing.
struct BatchCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NetworkMonitor.self) private var networkMonitor

    let book: Book
    let onComplete: (CaptureSession) -> Void
    let onCancel: () -> Void

    @State private var session: CaptureSession
    @State private var cameraService = CameraService()
    @State private var currentQuality: ImageQualityAnalyzer.QualityResult?
    @State private var lifecycleState = BatchCaptureLifecycleState()
    @State private var selectedCapture: PageCapture?
    @StateObject private var milestoneManager = MilestoneManager()
    private let cameraFramingProfile = CameraFramingProfile.quotePage

    // MARK: - Initialization

    init(book: Book, onComplete: @escaping (CaptureSession) -> Void, onCancel: @escaping () -> Void) {
        self.book = book
        self.onComplete = onComplete
        self.onCancel = onCancel
        self._session = State(initialValue: CaptureSession(book: book))
    }

    var body: some View {
        ZStack {
            // Camera preview background
            cameraPreviewLayer

            // Main content overlay
            VStack(spacing: 0) {
                // Top bar with session info
                sessionHeader
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)

                Spacer()

                // Bottom controls
                bottomControls
            }
        }
        .statusBarHidden()
        .toolbar(.hidden, for: .navigationBar)
        // Prevent the system tab bar from overlapping camera capture UI.
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cameraService.cleanup()
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
            Button("Save Draft") {
                saveDraft()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You captured \(session.totalPages) pages. Would you like to process them now or save as draft?")
        }
        .sheet(isPresented: $lifecycleState.showsOfflineConfirmation) {
            OfflineQueueConfirmationSheet(
                queuedCount: lifecycleState.queuedCount,
                bookTitle: book.title
            ) {
                lifecycleState.showsOfflineConfirmation = false
                onComplete(session)
            }
            .presentationDetents([.medium])
            .interactiveDismissDisabled()
        }
        .milestoneCelebration(manager: milestoneManager)
    }

    // MARK: - Camera Preview

    @ViewBuilder
    private var cameraPreviewLayer: some View {
        ZStack {
            CameraPreviewView(cameraService: cameraService, framingProfile: cameraFramingProfile)
                .ignoresSafeArea()

            if !cameraService.isSessionRunning {
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
            onCancel: cancelBatchCapture
        ) {
            Button {
                _ = lifecycleState.requestFinish(pageCount: session.totalPages)
            } label: {
                Text("Done")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(lifecycleState.canFinish(pageCount: session.totalPages) ? Color.brand : Color.white.opacity(0.45))
            }
            .buttonStyle(.plain)
            .disabled(!lifecycleState.canFinish(pageCount: session.totalPages))
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

            // Thumbnail strip
            if !session.captures.isEmpty {
                thumbnailStrip
            }

            // Capture button row
            HStack(spacing: Spacing.xl) {
                // Flash toggle placeholder
                Button {
                    // Toggle flash
                } label: {
                    Image(systemName: "bolt.slash.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                }

                // Main capture button
                CaptureButton(isProcessing: lifecycleState.isCapturing) {
                    await captureCurrentFrame()
                }

                // Switch camera placeholder
                Button {
                    try? cameraService.switchCamera()
                } label: {
                    Image(systemName: "camera.rotate")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                }
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
                        ThumbnailView(capture: capture)
                            .id(capture.id)
                            .onTapGesture {
                                selectedCapture = capture
                                lifecycleState.showsCaptureDetail = true
                            }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .frame(height: 70)
            .cameraChrome(cornerRadius: CornerRadius.lg)
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
            .onChange(of: session.captures.count) { _, _ in
                // Scroll to newest capture with smooth animation
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
            await cameraService.requestAuthorization()
            if cameraService.isAuthorized {
                try? cameraService.setupSession()
                cameraService.startSession()
            }
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

            HapticManager.captureSuccess()

            // Check for milestone celebrations
            checkMilestone(count: session.totalPages)

        } catch {
            HapticManager.error()
        }
    }

    private func removeCapture(_ capture: PageCapture) {
        // Remove from session
        session.captures.removeAll { $0.id == capture.id }
        session.totalPages = max(0, session.totalPages - 1)

        // Delete file
        capture.deleteImageFile()

        // Delete from context
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

        // Check network - if offline, queue for later processing
        if !networkMonitor.isConnected {
            Task {
                await queueCapturesForLaterProcessing()
            }
        } else {
            // Online - proceed with immediate processing
            onComplete(session)
        }
    }

    /// Queue all captures for offline processing
    private func queueCapturesForLaterProcessing() async {
        guard let queueManager = CaptureQueueManager.shared else {
            // No queue manager - fall back to normal flow
            await MainActor.run {
                onComplete(session)
            }
            return
        }

        var queued = 0
        for capture in session.captures {
            guard let image = capture.loadFullImage() else { continue }

            do {
                try await queueManager.addToQueue(image: image, book: book)
                queued += 1
            } catch {
                // Log error but continue with other captures
                print("Failed to queue capture: \(error)")
            }
        }

        await MainActor.run {
            switch lifecycleState.completeOfflineQueue(queuedCount: queued) {
            case .showOfflineConfirmation:
                HapticManager.success()
            case .complete:
                // No captures queued - proceed normally
                onComplete(session)
            case .none, .cancel, .showFinishConfirmation:
                break
            }
        }
    }

    private func saveDraft() {
        session.finishCapturing()
        modelContext.insert(session)
        try? modelContext.save()
        HapticManager.success()
        onCancel()
    }

    private var batchStatusPill: CaptureStatusPill? {
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
