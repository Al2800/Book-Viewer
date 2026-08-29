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

    init(books: [Book], on date: Date = Date(), calendar: Calendar = .current) {
        let quotes = books.flatMap(\.quotes)
        totalQuoteCount = quotes.count
        dailyPassage = DailyPassage.passage(from: quotes, on: date, calendar: calendar)
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

// MARK: - Browse Section

/// Browse controls card: grid/list view mode, book sort order, and the
/// camera-first add-book action.
struct LibraryBrowseSection: View {
    @Binding var viewMode: LibraryViewMode
    @Binding var sortOrder: LibrarySortOrder
    let onAddBook: () -> Void

    var body: some View {
        SectionCard(title: "Browse") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                LibraryControlRow(
                    icon: viewMode.systemImageName,
                    title: "Library View",
                    trailing: {
                        LibraryViewModeControl(viewMode: $viewMode)
                    }
                )

                LibraryControlRow(
                    icon: "arrow.up.arrow.down",
                    title: "Sort Books",
                    trailing: {
                        sortMenu
                    }
                )

                Button {
                    HapticManager.light()
                    onAddBook()
                } label: {
                    LibraryActionRow(
                        icon: "camera.viewfinder",
                        title: "Add New Book",
                        subtitle: "Scan an ISBN barcode"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sortMenu: some View {
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
            HStack(spacing: Spacing.xxs) {
                Text(sortOrder.displayName)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .font(.subheadline)
            .foregroundStyle(Color.brand)
            .frame(minHeight: 44, alignment: .trailing)
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.sortMenu)
    }
}

// MARK: - Organize Section

/// Organize card linking to the Collections and Tags screens.
struct LibraryOrganizeSection: View {
    var body: some View {
        SectionCard(title: "Organize") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NavigationLink(value: LibraryOrganizeDestination.collections) {
                    LibraryActionRow(
                        icon: "folder",
                        title: "Collections",
                        subtitle: "Group quotes by theme or project"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifiers.Library.collectionsRow)

                NavigationLink(value: LibraryOrganizeDestination.tags) {
                    LibraryActionRow(
                        icon: "tag",
                        title: "Tags",
                        subtitle: "Label quotes across your library"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifiers.Library.tagsRow)
            }
        }
    }
}

// MARK: - Filtered Books Empty Card

/// Shown in place of the Books section when the active collection/tag
/// filters exclude every book.
struct LibraryFilteredBooksEmptyCard: View {
    var body: some View {
        SectionCard(title: "Books") {
            Text("No books match the selected filters.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Empty state for library with entrance animation.
struct EmptyLibraryView: View {
    var onAddBook: (() -> Void)?

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                LibrarySummaryCard(bookCount: 0, quoteCount: 0, viewMode: .grid)

                SectionCard(title: "Library") {
                    emptyIntroRow

                    Button {
                        HapticManager.light()
                        onAddBook?()
                    } label: {
                        LibraryActionRow(
                            icon: "camera.viewfinder",
                            title: "Add Your First Book",
                            subtitle: "Scan an ISBN barcode"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.emptyState)
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.9)
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

    private var emptyIntroRow: some View {
        HStack(spacing: Spacing.md) {
            LibraryIconCircle(systemImage: "books.vertical", size: 44, font: .headline.weight(.semibold))

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("No Books Yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Text("Add your first book to start building a searchable quote library.")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)
        }
    }
}

struct LibrarySummaryCard: View {
    let bookCount: Int
    let quoteCount: Int
    let viewMode: LibraryViewMode

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.sm) {
                summaryPills
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                summaryPills
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .paperCard()
    }

    @ViewBuilder
    private var summaryPills: some View {
        LibrarySummaryPill(
            systemImage: "books.vertical",
            text: "\(bookCount) \(bookCount == 1 ? "Book" : "Books")"
        )
        LibrarySummaryPill(
            systemImage: "text.quote",
            text: "\(quoteCount) \(quoteCount == 1 ? "Quote" : "Quotes")"
        )
        LibrarySummaryPill(
            systemImage: viewMode.systemImageName,
            text: viewMode.summaryText
        )
    }
}

struct LibraryControlRow<Trailing: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let icon: String
    let title: String
    let subtitle: String?
    let trailing: Trailing

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            accessibilityLayout
        } else {
            standardLayout
        }
    }

    private var standardLayout: some View {
        HStack(spacing: Spacing.md) {
            LibraryIconCircle(systemImage: icon)

            rowLabels

            Spacer(minLength: 0)

            trailing
        }
    }

    private var accessibilityLayout: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.md) {
                LibraryIconCircle(systemImage: icon)
                rowLabels
            }

            trailing
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var rowLabels: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LibraryActionRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let icon: String
    let title: String
    var subtitle: String?

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            accessibilityLayout
        } else {
            standardLayout
        }
    }

    private var standardLayout: some View {
        HStack(spacing: Spacing.md) {
            LibraryIconCircle(systemImage: icon, foreground: Color.accent)

            rowLabels

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
        }
        .contentShape(Rectangle())
    }

    private var accessibilityLayout: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                LibraryIconCircle(systemImage: icon, foreground: Color.accent)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }

            rowLabels
        }
        .contentShape(Rectangle())
    }

    private var rowLabels: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LibrarySummaryPill: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .accessibilityHidden(true)

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

private struct LibraryIconCircle: View {
    let systemImage: String
    var size: CGFloat = 36
    var font: Font = .subheadline.weight(.semibold)
    var foreground: Color = .textPrimary

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.backgroundSecondary)
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                }

            Image(systemName: systemImage)
                .font(font)
                .foregroundStyle(foreground)
                .accessibilityHidden(true)
        }
    }
}
