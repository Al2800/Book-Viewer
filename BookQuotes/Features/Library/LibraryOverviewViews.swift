import SwiftUI

// MARK: - Daily Passage

/// Deterministic daily quote pick for the Library home.
/// The same passage shows all day and changes at midnight, favoring
/// favorites so rediscovery surfaces the lines the reader loved most.
struct DailyPassage {
    static func passage(
        from quotes: [Quote],
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> Quote? {
        guard !quotes.isEmpty else { return nil }

        let favorites = quotes.filter(\.isFavorite)
        let pool = favorites.isEmpty ? quotes : favorites

        // Stable ordering so the daily index resolves to the same quote
        // regardless of fetch order.
        let ordered = pool.sorted { $0.id.uuidString < $1.id.uuidString }
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return ordered[day % ordered.count]
    }
}

/// Single-pass snapshot of the Library home's derived quote data.
/// The library body previously walked every quote in the library up to
/// three times per render (daily passage, summary count, index-sync
/// change detection); this computes all of it in one pass per render.
struct LibraryHomeSnapshot {
    let totalQuoteCount: Int
    let dailyPassage: Quote?
    let recentQuotes: [Quote]
    let activeBook: Book?

    init(books: [Book], on date: Date = Date(), calendar: Calendar = .current) {
        let quotes = books.flatMap(\.quotes)
        totalQuoteCount = quotes.count
        let passage = DailyPassage.passage(from: quotes, on: date, calendar: calendar)
        dailyPassage = passage

        // Sort by most recently captured; deduplicate against daily passage so the same
        // quote is not shown in both places when the library has few quotes.
        let sorted = quotes.sorted(by: { $0.captureDate > $1.captureDate })
        if let passage {
            let withoutDaily = sorted.filter { $0.id != passage.id }
            recentQuotes = Array(withoutDaily.prefix(3))
        } else {
            recentQuotes = Array(sorted.prefix(3))
        }

        activeBook = ActiveReadingSessionStore.shared.activeBook(from: books)
    }
}

/// Epigraph-style card resurfacing one passage per day with gold bookmark ribbon.
struct DailyPassageCard: View {
    let quote: Quote

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "sparkle")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.gildedAccent)
                    Text("Daily Serendipity")
                        .sectionHeaderStyle()
                }

                Text("\u{201C}\(quote.text)\u{201D}")
                    .font(.quoteLarge)
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let book = quote.book {
                    Text("— \(book.title), \(book.author)")
                        .font(.attribution)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .padding(.trailing, Spacing.lg)

            BookmarkRibbon()
                .padding(.trailing, Spacing.lg)
                .offset(y: -4)
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.warmVellum)
                .overlay {
                    LinearGradient.cardHighlight
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.quoteBorder.opacity(0.7), lineWidth: Stroke.hairline.width)
                }
        )
        .elevation(.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Open quote")
    }

    private var accessibilityLabel: String {
        var label = "Daily Serendipity. \"\(quote.text)\""
        if let book = quote.book {
            label += ", by \(book.author), from \(book.title)"
        }
        return label
    }
}

/// Shape for a notched bookmark ribbon banner.
struct BookmarkRibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 6))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Gold foil bookmark ribbon pinned to cards.
struct BookmarkRibbon: View {
    var width: CGFloat = 20
    var height: CGFloat = 34

    var body: some View {
        BookmarkRibbonShape()
            .fill(LinearGradient.foilAccent)
            .frame(width: width, height: height)
            .overlay(alignment: .center) {
                Image(systemName: "sparkle")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.35))
                    .offset(y: -3)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 2, y: 2)
    }
}

// MARK: - Continue Reading Hero Card

/// Hero card highlighting the currently active book with 1-tap capture action.
struct ContinueReadingCard: View {
    let book: Book
    let onOpenBook: () -> Void
    let onCapture: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "bookmark.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.gildedAccent)
                Text("Continue Reading")
                    .sectionHeaderStyle()

                Spacer()

                Button(action: onOpenBook) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 32, height: 32)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open \(book.title)")
                .accessibilityHint("Opens book details")
            }

            HStack(alignment: .center, spacing: Spacing.md) {
                // Book cover thumbnail with spine depth
                Button(action: onOpenBook) {
                    bookThumbnail
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(book.title) cover")
                .accessibilityHint("Opens book details")

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Button(action: onOpenBook) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.title)
                                .font(.serifHeadline)
                                .foregroundStyle(Color.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Text(book.author)
                                .font(.authorName)
                                .foregroundStyle(Color.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(book.title) by \(book.author)")
                    .accessibilityHint("Opens book details")

                    HStack(spacing: Spacing.sm) {
                        HStack(spacing: 4) {
                            Image(systemName: "text.quote")
                                .font(.caption2)
                            Text("\(book.quotes.count) \(book.quotes.count == 1 ? "passage" : "passages")")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.textSecondary)

                        Spacer()

                        Button {
                            HapticManager.selection()
                            onCapture()
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "camera.fill")
                                    .font(.caption.weight(.semibold))
                                Text("Capture")
                                    .font(.uiPill)
                            }
                            .foregroundStyle(Color.darkLinen)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(LinearGradient.foilAccent)
                            )
                            .shadow(color: Color.gildedAccent.opacity(0.3), radius: 4, y: 2)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .accessibilityLabel("Capture passage for \(book.title)")
                        .accessibilityHint("Opens camera to capture a new quote")
                        .accessibilityIdentifier("continue_reading_capture_button")
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.warmVellum)
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.quoteBorder.opacity(0.7), lineWidth: Stroke.hairline.width)
                }
        )
        .elevation(.sm)
    }

    @ViewBuilder
    private var bookThumbnail: some View {
        if let coverData = book.coverThumbnailData ?? book.coverFullData, let uiImage = UIImage(data: coverData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .stroke(Color.quoteBorder.opacity(0.8), lineWidth: 0.5)
                }
                .shadow(color: Color.black.opacity(0.12), radius: 3, y: 2)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.xs)
                    .fill(LinearGradient.spineDepth)
                    .frame(width: 48, height: 68)

                Image(systemName: "book.closed")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.gildedAccent)
            }
            .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
        }
    }
}

// MARK: - Recent Passages

/// Passage-first section showcasing recently marked passages.
struct RecentPassagesSection: View {
    let quotes: [Quote]
    let onSelectQuote: (Quote) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "text.quote")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.gildedAccent)
                Text("Recent Passages")
                    .sectionHeaderStyle()
            }

            VStack(spacing: Spacing.sm) {
                ForEach(quotes) { quote in
                    Button {
                        HapticManager.light()
                        onSelectQuote(quote)
                    } label: {
                        RecentPassageRow(quote: quote)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Compact tactile card for a single recent passage.
struct RecentPassageRow: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("\u{201C}\(quote.text)\u{201D}")
                .font(.quoteBody)
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(4)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline) {
                if let book = quote.book {
                    Text("— \(book.title)\(pageSuffix)")
                        .font(.attribution)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if let marginNote = quote.marginNote, !marginNote.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "pencil.line")
                            .font(.caption2)
                            .foregroundStyle(Color.goldFoil)
                        Text(marginNote)
                            .font(.marginScriptSmall)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.warmVellum)
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                }
        )
        .elevation(.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Open quote details")
    }

    private var pageSuffix: String {
        guard let page = quote.pageNumber, page > 0 else { return "" }
        return " · p. \(page)"
    }

    private var accessibilityLabel: String {
        var label = "\"\(quote.text)\""
        if let book = quote.book {
            label += ", from \(book.title)"
            if let page = quote.pageNumber, page > 0 {
                label += ", page \(page)"
            }
        }
        if let marginNote = quote.marginNote, !marginNote.isEmpty {
            label += ". Margin note: \(marginNote)"
        }
        return label
    }
}

// MARK: - Browse Controls

/// Compact browse controls for the books section header: grid/list toggle and sort menu with accessible 44pt hit targets.
struct LibraryBrowseControls: View {
    @Binding var viewMode: LibraryViewMode
    @Binding var sortOrder: LibrarySortOrder

    var body: some View {
        HStack(spacing: Spacing.xs) {
            // View Mode Toggle Button
            Button {
                HapticManager.selection()
                withAnimation(.smoothSpring) {
                    viewMode = viewMode == .grid ? .list : .grid
                }
            } label: {
                Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.backgroundSecondary))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityIdentifiers.Library.viewModeToggle)
            .accessibilityLabel("Switch to \(viewMode == .grid ? "list" : "grid") view")

            // Sort Menu Button
            Menu {
                ForEach(LibrarySortOrder.allCases) { order in
                    Button {
                        HapticManager.selection()
                        sortOrder = order
                    } label: {
                        if sortOrder == order {
                            Label(order.displayName, systemImage: "checkmark")
                        } else {
                            Text(order.displayName)
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.backgroundSecondary))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Library.sortMenu)
            .accessibilityLabel("Sort books: \(sortOrder.displayName)")
        }
    }
}

// MARK: - Organize Section

/// Clean organize cards linking to Collections and Tags with responsive Dynamic Type support.
struct LibraryOrganizeSection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "folder")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.gildedAccent)
                Text("Organize")
                    .sectionHeaderStyle()
            }

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: Spacing.sm) {
                    collectionsLink
                    tagsLink
                }
            } else {
                HStack(spacing: Spacing.md) {
                    collectionsLink
                    tagsLink
                }
            }
        }
    }

    private var collectionsLink: some View {
        NavigationLink(value: LibraryOrganizeDestination.collections) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "folder")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.gildedAccent)

                Text("Collections")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.warmVellum)
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                    }
            )
            .elevation(.xs)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.collectionsRow)
    }

    private var tagsLink: some View {
        NavigationLink(value: LibraryOrganizeDestination.tags) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "tag")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.gildedAccent)

                Text("Tags")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.warmVellum)
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                    }
            )
            .elevation(.xs)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.tagsRow)
    }
}

// MARK: - Filtered Books Empty Card

/// Shown in place of the Books section when active collection/tag filters exclude every book.
struct LibraryFilteredBooksEmptyCard: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text("No books match the selected filters.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.warmVellum)
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                }
        )
        .elevation(.xs)
    }
}

/// Empty state for library with entrance animation.
struct EmptyLibraryView: View {
    var onAddBook: (() -> Void)?

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                Spacer(minLength: 40)

                ZStack {
                    Circle()
                        .fill(LinearGradient.foilAccent.opacity(0.12))
                        .frame(width: 90, height: 90)

                    Image(systemName: "books.vertical")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(Color.gildedAccent)
                }

                VStack(spacing: Spacing.sm) {
                    Text("Your Reading Sanctuary")
                        .font(.serifTitleLarge)
                        .foregroundStyle(Color.textPrimary)

                    Text("Turn the lines you mark in physical books into a searchable personal reading memory.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                Button {
                    HapticManager.selection()
                    onAddBook?()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "camera.viewfinder")
                        Text("Add Your First Book")
                    }
                    .font(.headline)
                    .foregroundStyle(Color.darkLinen)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(LinearGradient.foilAccent)
                    .clipShape(Capsule())
                    .shadow(color: Color.gildedAccent.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifiers.Library.addBookButton)

                Spacer()
            }
            .padding(Spacing.xl)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.emptyState)
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.95)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(0.2)) {
                hasAppeared = true
            }
        }
    }
}
