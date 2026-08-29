import SwiftUI
import SwiftData

// MARK: - Capture Tab Root View

/// Main orchestrator for the capture tab.
/// Provides zero-click active reading capture with HUD book switcher and direct camera preview.
struct CaptureTabRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateModified, order: .reverse) private var books: [Book]
    @Query private var captureSessions: [CaptureSession]
    @State private var cameraPermission = CameraPermissionService()
    @State private var captureFlow = CaptureFlowState(mode: .quoteCapture)
    @State private var selectedBook: Book?
    @State private var selectedDraft: CaptureSession?
    @State private var showingBookSwitcher = false
    var onBookCreated: ((Book) -> Void)?
    var onQuotesSaved: ((Book) -> Void)?
    @State private var showCoaching = false
    @AppStorage("hasCompletedCaptureCoaching") private var hasCompletedCoaching = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            // UI tests: bypass the camera permission gate so App Store media capture is deterministic.
            if UITestConfiguration.isUITesting || cameraPermission.isAuthorized {
                authorizedContent
            } else {
                CameraPermissionView()
            }
        }
        .environment(cameraPermission)
        .onAppear {
            cameraPermission.checkStatus()
            ensureActiveBook()
            if UITestConfiguration.isUITesting {
                hasCompletedCoaching = true
                showCoaching = false
                return
            }
            // Show coaching for first-time users
            if cameraPermission.isAuthorized && !hasCompletedCoaching {
                showCoaching = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                cameraPermission.onAppBecameActive()
            }
        }
        .onChange(of: cameraPermission.isAuthorized) { _, isAuthorized in
            // Show coaching after permission granted
            if isAuthorized && !hasCompletedCoaching {
                showCoaching = true
            }
        }
        .onChange(of: books) { _, newBooks in
            if selectedBook == nil {
                ensureActiveBook()
            }
        }
        .sheet(isPresented: $showCoaching) {
            FirstCaptureCoachingView(isPresented: $showCoaching)
                .presentationDetents([.large])
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showingBookSwitcher) {
            ActiveBookSwitcherSheet(
                currentBook: selectedBook,
                onSelectBook: { book in
                    selectedBook = book
                    ActiveReadingSessionStore.shared.setActiveBook(book)
                    handleCaptureFlowEvent(.switchActiveBook)
                },
                onScanNewBook: {
                    handleCaptureFlowEvent(.addNewBook)
                }
            )
        }
    }

    // MARK: - Authorized Content

    @ViewBuilder
    private var authorizedContent: some View {
        NavigationStack {
            if books.isEmpty && captureFlow.mode != .coverCapture {
                emptyLibraryPrompt
            } else {
                captureContent
            }
        }
    }

    // MARK: - Empty Library Prompt

    private var emptyLibraryPrompt: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient.foilAccent.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Color.gildedAccent)
            }

            VStack(spacing: Spacing.sm) {
                Text("Ready to Capture")
                    .font(.serifHeadline)
                    .foregroundStyle(Color.textPrimary)

                Text("Scan an ISBN barcode or enter a title to add your first book, then start saving passages instantly.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Button {
                HapticManager.selection()
                handleCaptureFlowEvent(.addNewBook)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "barcode.viewfinder")
                    Text("Add Your First Book")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.brand)
                .clipShape(Capsule())
                .shadow(color: Color.brand.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding()
    }

    // MARK: - Capture Content

    @ViewBuilder
    private var captureContent: some View {
        switch captureFlow.mode {
        case .selection, .bookSelection, .bookSelectionForBatch, .quoteCapture:
            QuoteCaptureFlowView(
                book: selectedBook,
                onComplete: {
                    let completedBook = selectedBook
                    handleCaptureFlowEvent(.completeQuoteCapture)
                    if let completedBook {
                        onQuotesSaved?(completedBook)
                    }
                },
                onCancel: {
                    handleCaptureFlowEvent(.cancelQuoteCapture)
                }
            )
            .id(captureFlow.quoteCaptureFlowID)
            .overlay(alignment: .top) {
                ActiveBookHUDView(
                    book: selectedBook,
                    onSwitchBook: {
                        showingBookSwitcher = true
                    }
                )
                .padding(.top, Spacing.sm)
            }

        case .coverCapture:
            CoverCaptureFlowView(
                onComplete: { book in
                    selectedBook = book
                    ActiveReadingSessionStore.shared.setActiveBook(book)
                    handleCaptureFlowEvent(.completeCoverCapture)
                    onBookCreated?(book)
                },
                onCancel: {
                    handleCaptureFlowEvent(.cancelCoverCapture)
                }
            )

        case .batchCapture:
            BatchCaptureFlowView(
                book: selectedBook,
                initialSession: selectedDraft,
                onComplete: { _ in
                    let completedBook = selectedBook
                    selectedDraft = nil
                    handleCaptureFlowEvent(.completeBatchCapture)
                    if let completedBook {
                        onQuotesSaved?(completedBook)
                    }
                },
                onCancel: {
                    selectedDraft = nil
                    handleCaptureFlowEvent(.cancelBatchCapture)
                }
            )
            .id(captureFlow.batchCaptureFlowID)
            .overlay(alignment: .top) {
                ActiveBookHUDView(
                    book: selectedBook,
                    onSwitchBook: {
                        showingBookSwitcher = true
                    }
                )
                .padding(.top, Spacing.sm)
            }
        }
    }

    private func ensureActiveBook() {
        if selectedBook == nil {
            selectedBook = ActiveReadingSessionStore.shared.resolveActiveBook(from: books)
        }
    }

    private func handleCaptureFlowEvent(_ event: CaptureFlowState.Event) {
        let command = captureFlow.handle(event)
        if command.clearsSelectedBook {
            selectedBook = nil
        }
    }

    private var resumableDrafts: [CaptureSession] {
        captureSessions
            .filter { $0.status == .readyToProcess && !$0.captures.isEmpty && $0.book != nil }
            .sorted { $0.dateStarted > $1.dateStarted }
    }

    private func resumeDraft(_ session: CaptureSession) {
        guard let book = session.book else { return }
        selectedBook = book
        selectedDraft = session
        handleCaptureFlowEvent(.resumeBatchCapture)
    }

    private func deleteDraft(_ session: CaptureSession) {
        session.deleteImageFiles()
        modelContext.delete(session)
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview("Capture Tab Root") {
    Group {
        if let container = ModelContainer.preview {
            CaptureTabRootView()
                .modelContainer(container)
        } else {
            Text("Preview unavailable")
                .foregroundStyle(.secondary)
        }
    }
}
