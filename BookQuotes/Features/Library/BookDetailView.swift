import SwiftUI
import SwiftData

// MARK: - BookDetailView

/// Detail view showing book metadata and all associated quotes.
struct BookDetailView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(RouterPath.self) private var router

    // MARK: - Properties

    let book: Book

    // MARK: - State

    @State private var sortOrder: BookDetailQuoteSortOrder = .dateAdded
    @State private var filterMarking: MarkingType?
    @State private var quoteSearchText = ""
    @State private var showSortMenu = false
    @State private var showFilterMenu = false
    @State private var showExportSheet = false
    @State private var showEditSheet = false
    @State private var showQuoteCaptureSheet = false
    @State private var quoteCaptureSheetID = UUID()
    @State private var showDeleteConfirmation = false
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Computed

    private var quotePresentation: BookDetailQuotePresentation {
        BookDetailQuotePresentation(quotes: book.quotes)
    }

    private var sortedQuotes: [Quote] {
        quotePresentation.visibleQuotes(
            filter: filterMarking,
            sortOrder: sortOrder,
            searchText: quoteSearchText
        )
    }

    private var isSearchingQuotes: Bool {
        !quoteSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var uniquePages: Int {
        quotePresentation.uniquePageCount
    }

    private var markingTypes: [MarkingType] {
        quotePresentation.markingTypes
    }

    private var deletionPrompt: BookDeletionPrompt {
        BookDeletionPrompt(
            bookTitle: book.title,
            quoteCount: book.quoteCount
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header with cover and metadata
                BookHeaderView(book: book)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)

                // Stats bar
                statsBar
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 15)

                // Filter/sort controls
                if book.hasQuotes {
                    controlsBar
                        .opacity(hasAppeared ? 1 : 0)
                }

                // Quotes list or empty state
                if book.quotes.isEmpty {
                    emptyQuotesView
                        .opacity(hasAppeared ? 1 : 0)
                } else if sortedQuotes.isEmpty {
                    noFilterResultsView
                        .opacity(hasAppeared ? 1 : 0)
                } else {
                    quotesGrid
                        .opacity(hasAppeared ? 1 : 0)
                }
            }
            .padding()
            .animation(reduceMotion ? .none : .smoothSpring.delay(0.1), value: hasAppeared)
        }
        .background(Color.backgroundPrimary)
        // Sort/filter change animations
        .animation(reduceMotion ? .none : .smoothSpring, value: sortOrder)
        .animation(reduceMotion ? .none : .smoothSpring, value: filterMarking)
        .animation(reduceMotion ? .none : .smoothSpring, value: quoteSearchText)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(0.15)) {
                hasAppeared = true
            }
        }
        .onChange(of: sortOrder) { _, _ in
            HapticManager.selection()
        }
        .onChange(of: filterMarking) { _, _ in
            HapticManager.selection()
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $quoteSearchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search quotes in this book"
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        HapticManager.light()
                        showExportSheet = true
                    } label: {
                        Label("Export Quotes", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        HapticManager.light()
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookDetail.editButton)

                    Button {
                        HapticManager.light()
                        // Force a fresh QuoteCaptureView each time the sheet is presented.
                        // SwiftUI may preserve sheet state across presentations, which can leave the capture
                        // view in a non-preview state (camera visible but no shutter controls).
                        quoteCaptureSheetID = UUID()
                        showQuoteCaptureSheet = true
                    } label: {
                        Label("Add Quotes", systemImage: "camera")
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookDetail.captureQuotesButton)

                    Divider()

                    Button(role: .destructive) {
                        HapticManager.warning()
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Book", systemImage: "trash")
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookDetail.deleteButton)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Common.moreMenuButton)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportView(book: book)
        }
        .sheet(isPresented: $showEditSheet) {
            BookEditView(mode: .edit(book))
        }
        .fullScreenCover(isPresented: $showQuoteCaptureSheet) {
            QuoteCaptureView(
                book: book,
                onComplete: {
                    showQuoteCaptureSheet = false
                },
                onCancel: {
                    showQuoteCaptureSheet = false
                }
            )
            .id(quoteCaptureSheetID)
        }
        .confirmationDialog(
            deletionPrompt.title,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(deletionPrompt.destructiveButtonTitle, role: .destructive) {
                deleteBook()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deletionPrompt.message)
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: Spacing.md) {
            StatBadge(
                label: "Quotes",
                value: "\(book.quoteCount)",
                icon: "quote.opening"
            )

            StatBadge(
                label: "Pages",
                value: "\(uniquePages)",
                icon: "doc"
            )

            if let rating = book.rating {
                StatBadge(
                    label: "Rating",
                    value: "\(rating)/5",
                    icon: "star.fill",
                    color: .accent
                )
            }

            Spacer()
        }
        .padding(Spacing.md)
        .paperCard()
    }

    // MARK: - Controls Bar

    private var controlsBar: some View {
        HStack {
            // Sort menu
            Menu {
                ForEach(BookDetailQuoteSortOrder.allCases, id: \.self) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            if sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Sort: \(sortOrder.rawValue)", systemImage: "arrow.up.arrow.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Filter menu
            Menu {
                Button {
                    filterMarking = nil
                } label: {
                    HStack {
                        Text("All Markings")
                        if filterMarking == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                ForEach(markingTypes, id: \.self) { type in
                    Button {
                        filterMarking = type
                    } label: {
                        HStack {
                            Text(type.displayName)
                            if filterMarking == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label(
                    filterMarking?.displayName ?? "Filter",
                    systemImage: filterMarking != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
                )
                .font(.caption)
                .foregroundStyle(filterMarking != nil ? Color.brand : .secondary)
            }
        }
        .padding(Spacing.md)
        .paperCard()
    }

    // MARK: - Quotes Grid

    private var quotesGrid: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(sortedQuotes) { quote in
                NavigationLink(value: quote) {
                    QuoteCardView(quote: quote)
                }
                .buttonStyle(.plain)
                // UI automation: make the tappable NavigationLink itself addressable.
                // QuoteCardView may collapse its subtree into a single accessibility element; putting the
                // identifier here ensures UI tests can tap and navigate reliably.
                .accessibilityIdentifier(AccessibilityIdentifiers.QuoteCard.container)
            }
        }
    }

    // MARK: - Empty States

    private var emptyQuotesView: some View {
        ContentUnavailableView {
            Label("No Quotes Yet", systemImage: "quote.opening")
        } description: {
            Text("Capture pages from this book to start extracting quotes.")
        } actions: {
            Button {
                HapticManager.light()
                quoteCaptureSheetID = UUID()
                showQuoteCaptureSheet = true
            } label: {
                Label("Capture Quotes", systemImage: "camera")
            }
            .glassButton()
            .accessibilityIdentifier(AccessibilityIdentifiers.BookDetail.captureQuotesButton)
        }
    }

    private var noFilterResultsView: some View {
        ContentUnavailableView {
            Label("No Matching Quotes", systemImage: "magnifyingglass")
        } description: {
            if isSearchingQuotes {
                Text("No quotes in this book match \u{201C}\(quoteSearchText)\u{201D}.")
            } else {
                Text("No quotes match the current filter.")
            }
        } actions: {
            if isSearchingQuotes {
                Button("Clear Search") {
                    quoteSearchText = ""
                }
                .buttonStyle(.secondaryCompact)
            }

            if filterMarking != nil {
                Button("Clear Filter") {
                    filterMarking = nil
                }
                .buttonStyle(.secondaryCompact)
            }
        }
    }

    // MARK: - Actions

    private func deleteBook() {
        do {
            try BookDeletionService(modelContext: modelContext).delete(book)
            HapticManager.notification(.success)
            dismiss()
        } catch {
            HapticManager.error()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BookDetailView(book: {
            let book = Book(title: "Atomic Habits", author: "James Clear")
            book.subtitle = "An Easy & Proven Way to Build Good Habits"
            book.status = .currentlyReading

            // Add some sample quotes
            for i in 1...5 {
                let quote = Quote(
                    text: "Sample quote number \(i). This is a longer text to show how quotes appear in the detail view.",
                    book: book
                )
                quote.pageNumber = i * 10
                quote.markingType = [.underline, .highlight, .marginLine][i % 3]
            }

            return book
        }())
    }
    .environment(RouterPath())
}
