import SwiftUI
import SwiftData

// MARK: - Capture Tab Root View

/// Main orchestrator for the capture tab.
/// Handles permission checking and mode switching between cover and quote capture.
struct CaptureTabRootView: View {
    @State private var cameraPermission = CameraPermissionService()
    @State private var captureMode: CaptureMode = .selection
    @State private var selectedBook: Book?
    @State private var showCoaching = false
    @AppStorage("hasCompletedCaptureCoaching") private var hasCompletedCoaching = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if cameraPermission.isAuthorized {
                authorizedContent
            } else {
                CameraPermissionView()
            }
        }
        .environment(cameraPermission)
        .onAppear {
            cameraPermission.checkStatus()
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
        switch captureMode {
        case .selection:
            CaptureModeSelectionView(
                onSelectCoverCapture: {
                    captureMode = .coverCapture
                },
                onSelectQuoteCapture: {
                    captureMode = .bookSelection
                },
                onSelectBatchCapture: {
                    captureMode = .bookSelection
                }
            )

        case .bookSelection:
            BookSelectionForCaptureView(
                onSelectBook: { book in
                    selectedBook = book
                    captureMode = .quoteCapture
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
        }
    }
}

// MARK: - Capture Mode

extension CaptureTabRootView {
    /// Modes for the capture tab
    enum CaptureMode {
        /// Initial mode selection screen
        case selection

        /// Selecting a book for quote capture
        case bookSelection

        /// Capturing a book cover
        case coverCapture

        /// Capturing quotes for a selected book
        case quoteCapture
    }
}

// MARK: - Mode Selection View

/// Initial view showing capture options
struct CaptureModeSelectionView: View {
    let onSelectCoverCapture: () -> Void
    let onSelectQuoteCapture: () -> Void
    let onSelectBatchCapture: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Hero section
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.brand)

                        Text("What would you like to capture?")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textPrimary)
                    }
                    .padding(.vertical, Spacing.xl)

                    // Capture options
                    VStack(spacing: Spacing.md) {
                        CaptureOptionCard(
                            title: "Add New Book",
                            description: "Photograph a book cover to add it to your library",
                            systemImage: "book.closed.fill",
                            color: .brand,
                            action: onSelectCoverCapture
                        )

                        CaptureOptionCard(
                            title: "Capture Quotes",
                            description: "Photograph pages with underlined or highlighted passages",
                            systemImage: "text.quote",
                            color: .accent,
                            action: onSelectQuoteCapture
                        )

                        CaptureOptionCard(
                            title: "Batch Mode",
                            description: "Capture multiple pages quickly, process all at once",
                            systemImage: "square.stack.3d.up.fill",
                            color: .success,
                            action: onSelectBatchCapture
                        )
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.large)
        }
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
        NavigationStack {
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

                    if let coverData = book.coverImageData,
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
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

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
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .strokeBorder(Color.brand, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))

                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color.brand)

                        Text("Add Book")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.brand)
                    }
                }
                .frame(height: 140)

                Text(" ") // Spacer for alignment
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
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
            NavigationStack {
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
