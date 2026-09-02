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
    @State private var showingDrafts = false
    @State private var draftErrorMessage: String?
    var onBookCreated: ((Book) -> Void)?
    var onQuotesSaved: ((Book) -> Void)?
    var onExit: (() -> Void)?
    @State private var showCoaching = false
    @AppStorage("hasCompletedCaptureCoaching") private var hasCompletedCoaching = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
            if isAuthorized && !hasCompletedCoaching {
                showCoaching = true
            }
        }
        .onChange(of: books) { _, _ in
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
        .sheet(isPresented: $showingDrafts) {
            SavedCaptureDraftsSheet(
                drafts: resumableDrafts,
                onResumeDraft: resumeDraft,
                onDeleteDraft: deleteDraft
            )
        }
        .alert("Could Not Delete Draft", isPresented: .init(
            get: { draftErrorMessage != nil },
            set: { if !$0 { draftErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(draftErrorMessage ?? "The saved capture session could not be deleted.")
        }
    }

    // MARK: - Authorized Content

    @ViewBuilder
    private var authorizedContent: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if books.isEmpty && captureFlow.mode != .coverCapture {
                    emptyLibraryPrompt
                } else {
                    captureContent
                }
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
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
                    .font(.largeTitle.weight(.light))
                    .foregroundStyle(Color.gildedAccent)
            }

            VStack(spacing: Spacing.sm) {
                Text("Ready to Capture")
                    .font(.serifTitleLarge)
                    .foregroundStyle(.white)

                Text("Scan an ISBN barcode or enter a title to add your first book, then start saving passages instantly.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.75))
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
                .font(.uiLabel)
                .foregroundStyle(.black)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.gildedAccent)
                .clipShape(Capsule())
                .shadow(color: Color.gildedAccent.opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Capture Content

    @ViewBuilder
    private var captureContent: some View {
        switch captureFlow.mode {
        case .selection, .bookSelection, .bookSelectionForBatch, .quoteCapture:
            QuoteCaptureFlowView(
                book: selectedBook,
                hidesHeaderBar: true,
                hidesTabBar: true,
                onComplete: {
                    let completedBook = selectedBook
                    handleCaptureFlowEvent(.completeQuoteCapture)
                    if let completedBook {
                        onQuotesSaved?(completedBook)
                    }
                },
                onCancel: exitCapture,
                onChooseBook: {
                    showingBookSwitcher = true
                }
            )
            .id(captureFlow.quoteCaptureFlowID)
            .overlay(alignment: .top) {
                if selectedBook != nil {
                    quoteCaptureHUD
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.sm)
                }
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
                hidesHeaderBar: true,
                hidesTabBar: true,
                onComplete: { _ in
                    let completedBook = selectedBook
                    selectedDraft = nil
                    handleCaptureFlowEvent(.completeBatchCapture)
                    if let completedBook {
                        onQuotesSaved?(completedBook)
                    }
                },
                onCancel: returnToSingleCapture,
                onChooseBook: {
                    showingBookSwitcher = true
                }
            )
            .id(captureFlow.batchCaptureFlowID)
        }
    }

    private var quoteCaptureHUD: some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            ActiveBookHUDView(
                book: selectedBook,
                onSwitchBook: {
                    showingBookSwitcher = true
                },
                onClose: exitCapture
            )

            Spacer(minLength: 0)

            CaptureModeMenuButton(
                currentMode: .singlePage,
                draftCount: resumableDrafts.count,
                onSelectBatch: {
                    selectedDraft = nil
                    handleCaptureFlowEvent(.toggleBatchMode)
                },
                onShowDrafts: {
                    showingDrafts = true
                }
            )
        }
    }

    private func exitCapture() {
        if let onExit {
            onExit()
            return
        }
        handleCaptureFlowEvent(.cancelQuoteCapture)
    }

    private func returnToSingleCapture() {
        selectedDraft = nil
        guard captureFlow.mode == .batchCapture else { return }
        handleCaptureFlowEvent(.toggleBatchMode)
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
        showingDrafts = false
        selectedBook = book
        selectedDraft = session
        ActiveReadingSessionStore.shared.setActiveBook(book)
        handleCaptureFlowEvent(.resumeBatchCapture)
    }

    private func deleteDraft(_ session: CaptureSession) {
        modelContext.delete(session)
        do {
            try modelContext.save()
            session.deleteImageFiles()
            HapticManager.success()
        } catch {
            draftErrorMessage = error.localizedDescription
            HapticManager.error()
        }
    }
}

// MARK: - Saved Capture Drafts

private struct SavedCaptureDraftsSheet: View {
    let drafts: [CaptureSession]
    let onResumeDraft: (CaptureSession) -> Void
    let onDeleteDraft: (CaptureSession) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if drafts.isEmpty {
                    ContentUnavailableView(
                        "No Saved Drafts",
                        systemImage: "tray",
                        description: Text("Batch sessions saved for later will appear here.")
                    )
                } else {
                    List {
                        ForEach(drafts) { draft in
                            Button {
                                dismiss()
                                onResumeDraft(draft)
                            } label: {
                                HStack(spacing: Spacing.md) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.uiLabel)
                                        .foregroundStyle(Color.brand)

                                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                                        Text(draft.book?.title ?? "Untitled Book")
                                            .font(.bookTitle)
                                            .foregroundStyle(Color.textPrimary)
                                            .lineLimit(1)

                                        Text("\(draft.totalPages) page\(draft.totalPages == 1 ? "" : "s") · \(draft.dateStarted.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Color.textTertiary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("capture_resume_draft_\(draft.id.uuidString)")
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    onDeleteDraft(draft)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.backgroundPrimary)
                }
            }
            .navigationTitle("Saved Drafts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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
