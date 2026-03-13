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
                CaptureSummaryCard()

                CaptureSectionCard(title: "Choose Capture Mode") {
                    CaptureModeRow(
                        title: "Add New Book",
                        subtitle: "Photograph a cover and create a library entry",
                        systemImage: "book.closed.fill",
                        accentColor: .brand,
                        accessibilityId: AccessibilityIdentifiers.Capture.modeSelectCover,
                        action: onSelectCoverCapture
                    )

                    CaptureModeRow(
                        title: "Capture Quotes",
                        subtitle: "Scan a marked page and review one passage at a time",
                        systemImage: "text.quote",
                        accentColor: .accent,
                        accessibilityId: AccessibilityIdentifiers.Capture.modeSelectQuote,
                        action: onSelectQuoteCapture
                    )

                    CaptureModeRow(
                        title: "Batch Mode",
                        subtitle: "Capture several pages first and process the session together",
                        systemImage: "square.stack.3d.up.fill",
                        accentColor: .success,
                        accessibilityId: AccessibilityIdentifiers.Capture.modeSelectBatch,
                        action: onSelectBatchCapture
                    )
                }

                CaptureSectionCard(title: "Before You Start") {
                    CaptureHintRow(
                        systemImage: "sun.max",
                        title: "Use even light",
                        subtitle: "Avoid shadows across the page and keep the full passage visible."
                    )

                    CaptureHintRow(
                        systemImage: "viewfinder",
                        title: "Fill the frame",
                        subtitle: "Keep the page square in view so extraction needs less correction."
                    )

                    CaptureHintRow(
                        systemImage: "highlighter",
                        title: "Pick the right flow",
                        subtitle: "Single capture works best for one page. Batch mode is better for a run of notes."
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Color.backgroundPrimary)
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

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if books.isEmpty {
                    emptyState
                } else {
                    librarySection
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
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
    private var librarySection: some View {
        VStack(spacing: Spacing.lg) {
            CaptureSectionCard(title: "Library") {
                AddBookLibraryRow(action: onAddNewBook)

                ForEach(books) { book in
                    CaptureBookRow(book: book) {
                        onSelectBook(book)
                    }
                }
            }

            CaptureSectionCard(title: "Capture Notes") {
                CaptureHintRow(
                    systemImage: "text.quote",
                    title: "Single capture",
                    subtitle: "Best when you want to review and save one marked page immediately."
                )

                CaptureHintRow(
                    systemImage: "square.stack.3d.up.fill",
                    title: "Batch capture",
                    subtitle: "Best when you are moving through several pages from the same book."
                )
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        CaptureSectionCard(title: "Library") {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.backgroundSecondary)
                            .frame(width: 44, height: 44)
                            .overlay {
                                Circle()
                                    .stroke(
                                        Color.quoteBorder.opacity(0.6),
                                        lineWidth: Stroke.hairline.width
                                    )
                            }

                        Image(systemName: "books.vertical")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Books Yet")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)

                        Text("Add a book first so quote capture has somewhere to save your passages.")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Button(action: onAddNewBook) {
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.backgroundSecondary)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            Color.quoteBorder.opacity(0.6),
                                            lineWidth: Stroke.hairline.width
                                        )
                                }

                            Image(systemName: "plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add Your First Book")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.textPrimary)

                            Text("Scan the cover or ISBN to start a capture session.")
                                .font(.caption)
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
            }
        }
    }
}

// MARK: - Capture Styling

private struct CaptureSectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.sectionHeader)
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: Spacing.sm) {
                content
            }
        }
        .padding(Spacing.lg)
        .paperCard()
    }
}

private struct CaptureSummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Capture")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.textPrimary)

            Text("Choose a flow, keep the page clear in frame, and save quotes into the right book without leaving the tab.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: Spacing.sm) {
                CaptureSummaryPill(systemImage: "camera", text: "Camera Ready")
                CaptureSummaryPill(systemImage: "text.viewfinder", text: "Review Before Save")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .paperCard()
    }
}

private struct CaptureSummaryPill: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(Color.textPrimary)
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(
            Capsule()
                .fill(Color.backgroundSecondary)
        )
        .overlay {
            Capsule()
                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
        }
    }
}

private struct CaptureModeRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accentColor: Color
    let accessibilityId: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.backgroundSecondary)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle()
                                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                        }

                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)

                    Text(subtitle)
                        .font(.caption)
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
        .applyCaptureAccessibilityIdentifier(accessibilityId)
    }
}

private struct CaptureHintRow: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.backgroundSecondary)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Circle()
                            .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                    }

                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct CaptureBookRow: View {
    let book: Book
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                captureCover

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)

                    Text(book.author)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)

                    Text(bookCaptureSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.bookSelectionCard)
    }

    private var bookCaptureSubtitle: String {
        if book.quoteCount == 0 {
            return "Ready for first capture"
        }

        let quoteLabel = book.quoteCount == 1 ? "quote" : "quotes"
        return "\(book.quoteCount) \(quoteLabel) saved"
    }

    @ViewBuilder
    private var captureCover: some View {
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
                    .font(.headline)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(width: 44, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
        }
    }
}

private struct AddBookLibraryRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.backgroundSecondary)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle()
                                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                        }

                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Add New Book")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)

                    Text("Scan a cover or ISBN before capturing quotes.")
                        .font(.caption)
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
    }
}

private extension View {
    @ViewBuilder
    func applyCaptureAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}

// MARK: - Legacy Grid Items

/// Grid item showing a book for selection
struct BookGridItem: View {
    let book: Book
    let action: () -> Void

    var body: some View {
        CaptureBookRow(book: book, action: action)
    }
}

/// Grid item for adding a new book
struct AddBookGridItem: View {
    let action: () -> Void

    var body: some View {
        AddBookLibraryRow(action: action)
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
