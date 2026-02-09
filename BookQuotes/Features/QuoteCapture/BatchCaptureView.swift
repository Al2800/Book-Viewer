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
    @State private var isCapturing = false
    @State private var showFinishConfirmation = false
    @State private var selectedCapture: PageCapture?
    @State private var showCaptureDetail = false
    @State private var showOfflineConfirmation = false
    @State private var queuedCount = 0
    @StateObject private var milestoneManager = MilestoneManager()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    .padding(.top, Spacing.md)

                Spacer()

                // Quality overlay (minimal)
                if let quality = currentQuality {
                    MinimalQualityOverlay(qualityResult: quality)
                        .padding(.bottom, Spacing.md)
                }

                // Bottom controls
                bottomControls
            }
        }
        .statusBarHidden()
        // Prevent the system tab bar from overlapping camera capture UI.
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cameraService.cleanup()
        }
        .sheet(isPresented: $showCaptureDetail) {
            if let capture = selectedCapture {
                CaptureDetailSheet(capture: capture, session: session) {
                    removeCapture(capture)
                }
            }
        }
        .confirmationDialog(
            "Finish Capture Session?",
            isPresented: $showFinishConfirmation,
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
        .sheet(isPresented: $showOfflineConfirmation) {
            OfflineQueueConfirmationSheet(
                queuedCount: queuedCount,
                bookTitle: book.title
            ) {
                showOfflineConfirmation = false
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
            CameraPreviewView(cameraService: cameraService)
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
        HStack {
            // Cancel button
            Button {
                if session.totalPages > 0 {
                    showFinishConfirmation = true
                } else {
                    onCancel()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            Spacer()

            // Page counter with animated count
            HStack(spacing: Spacing.xs) {
                Image(systemName: "doc.on.doc")
                Text("\(session.totalPages)")
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())
                Text("pages")
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .animation(.snappy, value: session.totalPages)

            Spacer()

            // Done button
            Button {
                if session.totalPages > 0 {
                    showFinishConfirmation = true
                }
            } label: {
                Text("Done")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(session.totalPages > 0 ? Color.brand : Color.white.opacity(0.5))
            }
            .disabled(session.totalPages == 0)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
    }

    // MARK: - Bottom Controls

    @ViewBuilder
    private var bottomControls: some View {
        VStack(spacing: Spacing.md) {
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
                CaptureButton(isProcessing: isCapturing) {
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
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.testImageButton)
                .disabled(isCapturing)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .glassFloating(cornerRadius: CornerRadius.xl)
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
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
                                showCaptureDetail = true
                            }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .frame(height: 70)
            .glassCard(cornerRadius: CornerRadius.lg)
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

    private func captureCurrentFrame() async {
        guard !isCapturing else { return }

        isCapturing = true
        defer { isCapturing = false }

        HapticManager.impact(.medium)

        do {
            let image = try await cameraService.capturePhoto()
            let previewSize = cameraService.currentPreviewSizeForCropping()
            let sessionID = session.id
            let qualityScore = currentQuality?.overallScore

            // Heavy work: crop, document detection, preprocess + thumbnail.
            let (imageData, thumbnailData, finalQualityScore) = try await Task.detached(priority: .userInitiated) { () throws -> (Data, Data, Double?) in
                var working = image
                if let previewSize {
                    working = (try? ImagePreprocessor.cropToAspectFillPreview(working, previewSize: previewSize)) ?? working
                }
                working = await ImagePreprocessor.autoCropDocument(working)

                let processed = try ImagePreprocessor.process(working, config: .highQuality)
                let thumbnailData = try ImagePreprocessor.createThumbnail(working)
                return (processed.data, thumbnailData, qualityScore)
            }.value

            // Create and save capture (disk IO; keep off the critical UI path).
            try PageCapture.ensureDirectory(for: sessionID)
            let imagePath = PageCapture.generateImagePath(sessionId: sessionID)
            try PageCapture.saveImage(imageData, to: imagePath)

            // Create capture record
            let capture = PageCapture(imagePath: imagePath, session: session)
            capture.thumbnailData = thumbnailData
            capture.qualityScore = finalQualityScore

            // Add to session
            session.addCapture(capture)
            modelContext.insert(capture)

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
            if queued > 0 {
                queuedCount = queued
                // Show confirmation sheet - user must dismiss explicitly
                showOfflineConfirmation = true
                HapticManager.success()
            } else {
                // No captures queued - proceed normally
                onComplete(session)
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
}

// MARK: - Thumbnail View

/// Small thumbnail showing a captured page
/// Features entrance animation and tap feedback
struct ThumbnailView: View {
    let capture: PageCapture

    @State private var hasAppeared = false
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let thumbnail = capture.loadThumbnail() {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.backgroundSecondary
            }

            // Status indicator
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    statusBadge
                }
            }
            .padding(Spacing.xxs)
        }
        .frame(width: 50, height: 65)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(Color.white.opacity(isPressed ? 0.6 : 0.3), lineWidth: isPressed ? 2 : 1)
        }
        // Press feedback
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .brightness(isPressed ? 0.1 : 0)
        .animation(reduceMotion ? .none : .quickSpring, value: isPressed)
        // Entrance animation
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.7)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                hasAppeared = true
            }
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.quickSpring) {
                isPressed = pressing
            }
        }, perform: {})
    }

    @ViewBuilder
    private var statusBadge: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
            .overlay {
                Image(systemName: capture.status.icon)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
            }
    }

    private var statusColor: Color {
        switch capture.status {
        case .pending: return .brand
        case .processing: return .warning
        case .completed: return .success
        case .failed: return .error
        }
    }
}

// MARK: - Capture Detail Sheet

/// Detail sheet for viewing/removing a specific capture
struct CaptureDetailSheet: View {
    let capture: PageCapture
    let session: CaptureSession
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // Full image
                if let image = capture.loadFullImage() {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                } else {
                    ContentUnavailableView {
                        Label("Image Not Found", systemImage: "photo")
                    }
                }

                // Metadata
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    LabeledContent("Page", value: "\(capture.orderIndex + 1) of \(session.totalPages)")
                    LabeledContent("Status", value: capture.status.rawValue.capitalized)
                    if let quality = capture.qualityScore {
                        LabeledContent("Quality", value: "\(Int(quality * 100))%")
                    }
                }
                .padding()
                .background(Color.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                Spacer()

                // Delete button
                Button(role: .destructive) {
                    onDelete()
                    dismiss()
                } label: {
                    Label("Remove Page", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.error)
            }
            .padding(Spacing.lg)
            .navigationTitle("Page \(capture.orderIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Offline Queue Confirmation Sheet

/// Full confirmation sheet shown when captures are queued for offline processing.
/// Provides clear messaging and explicit dismiss action instead of auto-dismissing toast.
struct OfflineQueueConfirmationSheet: View {
    let queuedCount: Int
    let bookTitle: String
    let onDismiss: () -> Void

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Success icon with animation
            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.brand)
                    .symbolEffect(.bounce, options: .nonRepeating, isActive: hasAppeared && !reduceMotion)
            }
            .scaleEffect(hasAppeared ? 1 : 0.5)
            .opacity(hasAppeared ? 1 : 0)

            // Main message
            VStack(spacing: Spacing.sm) {
                Text("Saved for Later")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)

                Text("\(queuedCount) page\(queuedCount == 1 ? "" : "s") from \"\(bookTitle)\"")
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)

            // Explanation
            VStack(spacing: Spacing.md) {
                InfoRow(
                    icon: "wifi.slash",
                    text: "You're currently offline"
                )

                InfoRow(
                    icon: "arrow.triangle.2.circlepath",
                    text: "Pages will process automatically when connected"
                )

                InfoRow(
                    icon: "bell.badge",
                    text: "You'll be notified when quotes are ready"
                )
            }
            .padding(Spacing.lg)
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)

            Spacer()

            // Dismiss button
            Button {
                HapticManager.light()
                onDismiss()
            } label: {
                Text("Got it")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brand)
            .opacity(hasAppeared ? 1 : 0)
        }
        .padding(Spacing.xl)
        .background(Color.backgroundPrimary)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(0.1)) {
                hasAppeared = true
            }
        }
    }
}

/// Helper row for info items
private struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.brand)
                .frame(width: 28)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Offline Queue Toast (Deprecated - kept for backwards compatibility)

/// Toast notification shown when captures are queued for offline processing
/// @available(*, deprecated, message: "Use OfflineQueueConfirmationSheet instead")
struct OfflineQueueToast: View {
    let count: Int

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title3)
                .foregroundStyle(Color.brand)
                .symbolEffect(.pulse, options: .repeating.speed(0.5), isActive: !reduceMotion)

            VStack(alignment: .leading, spacing: 2) {
                Text("Saved Offline")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text("\(count) page\(count == 1 ? "" : "s") will process when connected")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .elevation(.lg, colorScheme: colorScheme)
        .padding(.top, Spacing.xl)
        // Entrance animation
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : -20)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Batch Capture") {
    Group {
        if let container = ModelContainer.preview {
            BatchCaptureView(
                book: Book(title: "Test Book", author: "Author"),
                onComplete: { _ in },
                onCancel: {}
            )
            .modelContainer(container)
            .environment(NetworkMonitor())
        } else {
            Text("Preview unavailable")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Offline Confirmation") {
    OfflineQueueConfirmationSheet(
        queuedCount: 5,
        bookTitle: "Thinking, Fast and Slow"
    ) {
        print("Dismissed")
    }
}

#Preview("Offline Toast (Deprecated)") {
    OfflineQueueToast(count: 5)
        .padding()
}
