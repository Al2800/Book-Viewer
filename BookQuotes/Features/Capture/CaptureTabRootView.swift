import SwiftUI
import SwiftData

// MARK: - Capture Tab Root View

/// Main orchestrator for the capture tab.
/// Handles permission checking and mode switching between cover and quote capture.
struct CaptureTabRootView: View {
    @State private var cameraPermission = CameraPermissionService()
    @State private var captureMode: CaptureMode = .selection
    @State private var selectedBook: Book?
    // SwiftUI can preserve view state when switching between enum-driven branches.
    // Force fresh capture flows so we never return to a camera preview with stale state (e.g. missing shutter).
    @State private var quoteCaptureFlowID = UUID()
    @State private var batchCaptureFlowID = UUID()
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
        .sheet(isPresented: $showCoaching) {
            FirstCaptureCoachingView(isPresented: $showCoaching)
                .presentationDetents([.large])
                .interactiveDismissDisabled()
        }
    }

    // MARK: - Authorized Content

    @ViewBuilder
    private var authorizedContent: some View {
        NavigationStack {
            captureContent
        }
    }

    @ViewBuilder
    private var captureContent: some View {
        switch captureMode {
        case .selection:
            CaptureModeSelectionView(
                onSelectCoverCapture: {
                    HapticManager.light()
                    captureMode = .coverCapture
                },
                onSelectQuoteCapture: {
                    HapticManager.light()
                    captureMode = .bookSelection
                },
                onSelectBatchCapture: {
                    HapticManager.light()
                    captureMode = .bookSelectionForBatch
                }
            )

        case .bookSelection:
            BookSelectionForCaptureView(
                onSelectBook: { book in
                    HapticManager.medium()
                    selectedBook = book
                    quoteCaptureFlowID = UUID()
                    captureMode = .quoteCapture
                },
                onAddNewBook: {
                    captureMode = .coverCapture
                },
                onCancel: {
                    captureMode = .selection
                }
            )

        case .bookSelectionForBatch:
            BookSelectionForCaptureView(
                onSelectBook: { book in
                    HapticManager.medium()
                    selectedBook = book
                    batchCaptureFlowID = UUID()
                    captureMode = .batchCapture
                },
                onAddNewBook: {
                    captureMode = .coverCapture
                },
                onCancel: {
                    captureMode = .selection
                }
            )

        case .coverCapture:
            CoverCaptureFlowView(
                onComplete: { _ in
                    captureMode = .selection
                },
                onCancel: {
                    captureMode = .selection
                }
            )

        case .quoteCapture:
            QuoteCaptureFlowView(
                book: selectedBook,
                onComplete: {
                    selectedBook = nil
                    captureMode = .selection
                },
                onCancel: {
                    selectedBook = nil
                    captureMode = .selection
                }
            )
            .id(quoteCaptureFlowID)

        case .batchCapture:
            BatchCaptureFlowView(
                book: selectedBook,
                onComplete: { _ in
                    selectedBook = nil
                    captureMode = .selection
                },
                onCancel: {
                    selectedBook = nil
                    captureMode = .selection
                }
            )
            .id(batchCaptureFlowID)
        }
    }
}

// MARK: - Capture Mode

extension CaptureTabRootView {
    /// Modes for the capture tab
    enum CaptureMode {
        /// Initial mode selection screen
        case selection

        /// Selecting a book for single quote capture
        case bookSelection

        /// Selecting a book for batch capture
        case bookSelectionForBatch

        /// Capturing a book cover
        case coverCapture

        /// Capturing quotes for a selected book (single mode)
        case quoteCapture

        /// Batch capturing multiple pages for a selected book
        case batchCapture
    }
}

// MARK: - Mode Selection View

/// Initial view showing capture options
struct CaptureModeSelectionView: View {
    let onSelectCoverCapture: () -> Void
    let onSelectQuoteCapture: () -> Void
    let onSelectBatchCapture: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Capture options
                VStack(spacing: Spacing.md) {
                    CaptureOptionCard(
                        title: "Add New Book",
                        description: "Photograph a book cover to add it to your library",
                        systemImage: "book.closed.fill",
                        color: .brand,
                        accessibilityId: AccessibilityIdentifiers.Capture.modeSelectCover,
                        action: onSelectCoverCapture
                    )

                    CaptureOptionCard(
                        title: "Capture Quotes",
                        description: "Photograph pages with underlined or highlighted passages",
                        systemImage: "text.quote",
                        color: .accent,
                        accessibilityId: AccessibilityIdentifiers.Capture.modeSelectQuote,
                        action: onSelectQuoteCapture
                    )

                    CaptureOptionCard(
                        title: "Batch Mode",
                        description: "Capture multiple pages quickly, process all at once",
                        systemImage: "square.stack.3d.up.fill",
                        color: .success,
                        accessibilityId: AccessibilityIdentifiers.Capture.modeSelectBatch,
                        action: onSelectBatchCapture
                    )
                }
            }
            .padding(Spacing.lg)
        }
        .background(
            LinearGradient(
                colors: [Color.backgroundPrimary, Color.backgroundSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Capture")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Book Selection for Capture View

/// Grid view for selecting a book to capture quotes from
struct BookSelectionForCaptureView: View {
    let onSelectBook: (Book) -> Void
    let onAddNewBook: () -> Void
    let onCancel: () -> Void

    @Query(sort: \Book.dateLastQuoteAdded, order: .reverse)
    private var books: [Book]

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: Spacing.md)
    ]

    var body: some View {
        ScrollView {
            if books.isEmpty {
                emptyState
            } else {
                bookGrid
            }
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Select Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }
        }
    }

    @ViewBuilder
    private var bookGrid: some View {
        LazyVGrid(columns: columns, spacing: Spacing.lg) {
            // Add new book option
            AddBookGridItem(action: onAddNewBook)

            // Existing books
            ForEach(books) { book in
                BookGridItem(book: book) {
                    onSelectBook(book)
                }
            }
        }
        .padding(Spacing.lg)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundStyle(Color.textTertiary)

            VStack(spacing: Spacing.sm) {
                Text("No Books Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text("Add a book first by capturing its cover")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onAddNewBook()
            } label: {
                Label("Add Your First Book", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(.brand)

            Spacer()
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Book Grid Item

/// Grid item showing a book for selection
struct BookGridItem: View {
    let book: Book
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                // Cover placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.backgroundSecondary)

                    if let coverData = book.coverThumbnailData ?? book.coverFullData,
                       let uiImage = UIImage(data: coverData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "book.closed.fill")
                            .font(.title)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                .elevation(.sm)

                // Title
                Text(book.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.bookSelectionCard)
    }
}

// MARK: - Add Book Grid Item

/// Grid item for adding a new book
struct AddBookGridItem: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color.backgroundCard)
                        .overlay {
                            LinearGradient.cardHighlight
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .stroke(Color.accent.opacity(0.6), lineWidth: Stroke.thin.width)
                        }

                    VStack(spacing: Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 42, height: 42)
                                .overlay {
                                    Circle()
                                        .stroke(Color.accent.opacity(0.5), lineWidth: Stroke.hairline.width)
                                }

                            Image(systemName: "plus")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color.accent)
                        }

                        Text("Add Book")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                .frame(height: 140)

                Text("Scan cover or ISBN")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Capture Flow Views

/// Cover capture flow wrapper - delegates to CoverCaptureView
struct CoverCaptureFlowView: View {
    let onComplete: (Book) -> Void
    let onCancel: () -> Void

    var body: some View {
        CoverCaptureView(
            onComplete: onComplete,
            onCancel: onCancel
        )
    }
}

/// Quote capture flow wrapper - delegates to actual QuoteCaptureView
struct QuoteCaptureFlowView: View {
    let book: Book?
    let onComplete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        if let book = book {
            QuoteCaptureView(book: book, onComplete: onComplete)
        } else {
            // Fallback for missing book (shouldn't happen in normal flow)
            ContentUnavailableView {
                Label("No Book Selected", systemImage: "book.closed")
            } description: {
                Text("Please select a book first")
            }
            .navigationTitle("Capture Quotes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

/// Batch capture flow wrapper - delegates to BatchCaptureView then ExtractionReviewView
struct BatchCaptureFlowView: View {
    let book: Book?
    let onComplete: (CaptureSession) -> Void
    let onCancel: () -> Void

    @State private var capturedSession: CaptureSession?
    @State private var showExtractionReview = false

    var body: some View {
        if let book = book {
            BatchCaptureView(
                book: book,
                onComplete: { session in
                    // Show extraction review instead of completing immediately
                    capturedSession = session
                    showExtractionReview = true
                },
                onCancel: onCancel
            )
            .fullScreenCover(isPresented: $showExtractionReview) {
                if let session = capturedSession {
                    ExtractionReviewView(
                        session: session,
                        book: book,
                        onComplete: {
                            showExtractionReview = false
                            onComplete(session)
                        }
                    )
                }
            }
        } else {
            // Fallback for missing book (shouldn't happen in normal flow)
            ContentUnavailableView {
                Label("No Book Selected", systemImage: "book.closed")
            } description: {
                Text("Please select a book first")
            }
            .navigationTitle("Batch Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
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

#Preview("Mode Selection") {
    CaptureModeSelectionView(
        onSelectCoverCapture: {},
        onSelectQuoteCapture: {},
        onSelectBatchCapture: {}
    )
}

#Preview("Book Selection") {
    Group {
        if let container = ModelContainer.preview {
            BookSelectionForCaptureView(
                onSelectBook: { _ in },
                onAddNewBook: {},
                onCancel: {}
            )
            .modelContainer(container)
        } else {
            Text("Preview unavailable")
                .foregroundStyle(.secondary)
        }
    }
}
