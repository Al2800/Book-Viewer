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

    @State private var sortOrder: SortOrder = .dateAdded
    @State private var filterMarking: MarkingType?
    @State private var showSortMenu = false
    @State private var showFilterMenu = false
    @State private var showExportSheet = false
    @State private var showEditSheet = false
    @State private var showQuoteCaptureSheet = false
    @State private var quoteCaptureSheetID = UUID()
    @State private var showDeleteConfirmation = false
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Sort Order

    enum SortOrder: String, CaseIterable {
        case dateAdded = "Date Added"
        case pageNumber = "Page Number"
        case markingType = "Marking Type"
        case favorite = "Favorites First"
    }

    // MARK: - Computed

    private var sortedQuotes: [Quote] {
        var quotes = book.quotes

        // Apply filter
        if let filter = filterMarking {
            quotes = quotes.filter { $0.markingType == filter }
        }

        // Apply sort
        switch sortOrder {
        case .dateAdded:
            quotes.sort { $0.captureDate > $1.captureDate }
        case .pageNumber:
            quotes.sort { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }
        case .markingType:
            quotes.sort { $0.markingType.rawValue < $1.markingType.rawValue }
        case .favorite:
            quotes.sort { ($0.isFavorite ? 0 : 1) < ($1.isFavorite ? 0 : 1) }
        }

        return quotes
    }

    private var uniquePages: Int {
        Set(book.quotes.compactMap { $0.pageNumber }).count
    }

    private var markingTypes: [MarkingType] {
        Array(Set(book.quotes.map { $0.markingType })).sorted { $0.rawValue < $1.rawValue }
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
        .sheet(isPresented: $showQuoteCaptureSheet) {
            NavigationStack {
                QuoteCaptureView(book: book, onComplete: {
                    showQuoteCaptureSheet = false
                })
                .id(quoteCaptureSheetID)
            }
        }
        .confirmationDialog(
            "Delete \"\(book.title)\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Book and All Quotes", role: .destructive) {
                deleteBook()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the book and all \(book.quoteCount) quote\(book.quoteCount == 1 ? "" : "s"). This cannot be undone.")
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
                    color: .yellow
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
                ForEach(SortOrder.allCases, id: \.self) { order in
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
                .foregroundStyle(filterMarking != nil ? Color.accentColor : .secondary)
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
            Text("No quotes match the current filter.")
        } actions: {
            Button("Clear Filter") {
                filterMarking = nil
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Actions

    private func deleteBook() {
        // SwiftData cascade delete handles quotes automatically
        modelContext.delete(book)
        do {
            try modelContext.save()
            HapticManager.notification(.success)
        } catch {
            HapticManager.error()
        }
        dismiss()
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
