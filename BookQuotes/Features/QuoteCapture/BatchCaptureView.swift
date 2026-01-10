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
    @State private var showQueuedToast = false
    @State private var queuedCount = 0

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
        .overlay(alignment: .top) {
            // Offline queue toast
            if showQueuedToast {
                OfflineQueueToast(count: queuedCount)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: showQueuedToast)
            }
        }
    }

    // MARK: - Camera Preview

    @ViewBuilder
    private var cameraPreviewLayer: some View {
        // Placeholder for camera preview
        // In production, this would be CameraPreviewView(cameraService: cameraService)
        ZStack {
            Color.black
                .ignoresSafeArea()

            if !cameraService.isSessionRunning {
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
                    .padding(Spacing.sm)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            // Page counter
            HStack(spacing: Spacing.xs) {
                Image(systemName: "doc.on.doc")
                Text("\(session.totalPages)")
                    .fontWeight(.semibold)
                Text("pages")
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

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
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            .disabled(session.totalPages == 0)
        }
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
                CaptureButton(isCapturing: isCapturing) {
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
        }
        .padding(.horizontal, Spacing.lg)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
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
            .onChange(of: session.captures.count) { _, _ in
                // Scroll to newest capture
                if let lastCapture = session.captures.last {
                    withAnimation {
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
        HapticManager.impact(.medium)

        do {
            let image = try await cameraService.capturePhoto()

            // Create and save capture
            try PageCapture.ensureDirectory(for: session.id)
            let imagePath = PageCapture.generateImagePath(sessionId: session.id)

            // Process image
            let processed = try ImagePreprocessor.process(image, config: .highQuality)
            try PageCapture.saveImage(processed.data, to: imagePath)

            // Create thumbnail
            let thumbnailData = try ImagePreprocessor.createThumbnail(image)

            // Create capture record
            let capture = PageCapture(imagePath: imagePath, session: session)
            capture.thumbnailData = thumbnailData
            capture.qualityScore = currentQuality?.overallScore

            // Add to session
            session.addCapture(capture)
            modelContext.insert(capture)

            HapticManager.captureSuccess()

        } catch {
            HapticManager.error()
        }

        isCapturing = false
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
                showQueuedToast = true

                // Still call onComplete to dismiss the capture flow
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onComplete(session)
                }
            } else {
                onComplete(session)
            }
        }
    }

    private func saveDraft() {
        session.status = .readyToProcess
        modelContext.insert(session)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Capture Button

/// Large capture button with press animation
struct CaptureButton: View {
    let isCapturing: Bool
    let action: () async -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 72, height: 72)

                // Inner circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
                    .scaleEffect(isPressed ? 0.9 : 1.0)

                // Processing indicator
                if isCapturing {
                    ProgressView()
                        .tint(.black)
                }
            }
        }
        .disabled(isCapturing)
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.quickSpring) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.quickSpring) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Thumbnail View

/// Small thumbnail showing a captured page
struct ThumbnailView: View {
    let capture: PageCapture

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
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        }
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

// MARK: - Offline Queue Toast

/// Toast notification shown when captures are queued for offline processing
struct OfflineQueueToast: View {
    let count: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title3)
                .foregroundStyle(Color.brand)

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
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
        .padding(.top, Spacing.xl)
    }
}

// MARK: - Preview

#Preview("Batch Capture") {
    BatchCaptureView(
        book: Book(title: "Test Book", author: "Author"),
        onComplete: { _ in },
        onCancel: {}
    )
    .modelContainer(.preview)
    .environment(NetworkMonitor())
}

#Preview("Offline Toast") {
    OfflineQueueToast(count: 5)
        .padding()
}
