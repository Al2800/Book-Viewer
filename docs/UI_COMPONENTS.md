# UI Components Specification

## Design Philosophy

BookQuotes presents literary content with elegance and respect. The UI should feel:
- **Literary**: Typography-forward, reminiscent of quality book design
- **Calm**: Muted colors, generous whitespace, no visual noise
- **Tactile**: Subtle shadows, soft corners, gentle transitions
- **Focused**: Content takes center stage, chrome fades away

---

## Design System

### Color Tokens

```swift
import SwiftUI

extension Color {
    // MARK: - Brand Colors
    static let brand = Color("Brand") // Deep warm blue #2C3E50
    static let brandLight = Color("BrandLight") // #34495E
    static let accent = Color("Accent") // Warm gold #D4A574

    // MARK: - Background
    static let backgroundPrimary = Color("BackgroundPrimary") // Warm white #FAFAF8
    static let backgroundSecondary = Color("BackgroundSecondary") // Subtle cream #F5F5F0
    static let backgroundCard = Color("BackgroundCard") // Paper white #FFFFFF

    // MARK: - Text
    static let textPrimary = Color("TextPrimary") // Rich black #1A1A1A
    static let textSecondary = Color("TextSecondary") // Soft gray #6B6B6B
    static let textTertiary = Color("TextTertiary") // Light gray #9A9A9A

    // MARK: - Semantic
    static let success = Color("Success") // Muted green #4A7C59
    static let warning = Color("Warning") // Muted amber #C9A227
    static let error = Color("Error") // Muted red #A35D5D

    // MARK: - Quote Card
    static let quoteBackground = Color("QuoteBackground") // Warm paper #FFFEF9
    static let quoteBorder = Color("QuoteBorder") // Subtle line #E8E8E0
}

// MARK: - Dark Mode Support

extension ShapeStyle where Self == Color {
    static var adaptiveBackground: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
                : UIColor(red: 0.98, green: 0.98, blue: 0.97, alpha: 1)
        })
    }
}
```

### Typography

```swift
import SwiftUI

extension Font {
    // MARK: - Display (for large quotes)
    static let quoteDisplay = Font.system(.title2, design: .serif)
    static let quoteLarge = Font.system(.title3, design: .serif)
    static let quoteBody = Font.system(.body, design: .serif)

    // MARK: - Attribution
    static let attribution = Font.system(.subheadline, design: .serif).italic()
    static let attributionSmall = Font.system(.caption, design: .serif).italic()

    // MARK: - UI Text
    static let bookTitle = Font.system(.headline, design: .serif).weight(.semibold)
    static let authorName = Font.system(.subheadline, design: .serif)
    static let sectionHeader = Font.system(.footnote).weight(.semibold)
    static let bodyText = Font.system(.body)
    static let caption = Font.system(.caption)
}

// MARK: - Line Spacing

extension View {
    func quoteTextStyle() -> some View {
        self
            .font(.quoteBody)
            .lineSpacing(6)
            .foregroundStyle(.textPrimary)
    }
}
```

### Spacing & Layout

```swift
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

enum CornerRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}
```

---

## Core Components

### QuoteCard

The hero component - displays a single quote beautifully.

```swift
struct QuoteCardView: View {
    let quote: Quote
    var showAttribution: Bool = true
    var style: QuoteCardStyle = .default

    enum QuoteCardStyle {
        case `default`
        case compact
        case featured
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Opening quotation mark
            openingQuoteMark

            // Quote text
            Text(quote.text)
                .quoteTextStyle()
                .fixedSize(horizontal: false, vertical: true)

            // Margin note (if present)
            if let marginNote = quote.marginNote {
                marginNoteView(marginNote)
            }

            // Attribution
            if showAttribution {
                attributionView
            }
        }
        .padding(style == .compact ? Spacing.lg : Spacing.xl)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    // MARK: - Subviews

    private var openingQuoteMark: some View {
        Text("\u{201C}")
            .font(.system(size: style == .featured ? 64 : 48, design: .serif))
            .foregroundStyle(.textTertiary.opacity(0.4))
            .offset(x: -4, y: 0)
    }

    private func marginNoteView(_ note: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "note.text")
                .font(.caption)
                .foregroundStyle(.textTertiary)

            Text(note)
                .font(.caption)
                .foregroundStyle(.textSecondary)
                .italic()
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(.backgroundSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
    }

    private var attributionView: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let book = quote.book {
                    Text(book.title)
                        .font(.attribution)
                        .foregroundStyle(.textSecondary)

                    Text("by \(book.author)")
                        .font(.attributionSmall)
                        .foregroundStyle(.textTertiary)
                }
            }

            Spacer()

            if let page = quote.pageNumber {
                Text("p. \(page)")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(.backgroundSecondary)
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26, *) {
            Color.clear
                .glassEffect(.regular.tint(.accent.opacity(0.05)), in: .rect(cornerRadius: CornerRadius.lg))
        } else {
            Color.quoteBackground
        }
    }
}
```

### BookCoverView

Displays a book cover with consistent styling.

```swift
struct BookCoverView: View {
    let book: Book
    var size: CoverSize = .medium

    enum CoverSize {
        case small // 60x90
        case medium // 100x150
        case large // 160x240
        case hero // 200x300

        var width: CGFloat {
            switch self {
            case .small: return 60
            case .medium: return 100
            case .large: return 160
            case .hero: return 200
            }
        }

        var height: CGFloat { width * 1.5 }
    }

    var body: some View {
        Group {
            if let coverData = book.coverThumbnailData,
               let uiImage = UIImage(data: coverData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholderCover
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: coverCornerRadius))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }

    private var placeholderCover: some View {
        ZStack {
            LinearGradient(
                colors: [.brand, .brandLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: Spacing.sm) {
                Text(book.title)
                    .font(size == .small ? .caption2 : .caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .lineLimit(3)

                Text(book.author)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
            }
            .padding(Spacing.sm)
        }
    }

    private var coverCornerRadius: CGFloat {
        switch size {
        case .small: return 4
        case .medium: return 6
        case .large, .hero: return 8
        }
    }
}
```

### BookListRow

A book item for list views.

```swift
struct BookListRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: Spacing.md) {
            BookCoverView(book: book, size: .small)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(book.title)
                    .font(.bookTitle)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(2)

                Text(book.author)
                    .font(.authorName)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    statusBadge

                    if book.quoteCount > 0 {
                        Label("\(book.quoteCount)", systemImage: "quote.opening")
                            .font(.caption)
                            .foregroundStyle(.textTertiary)
                    }
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }

    private var statusBadge: some View {
        Text(book.status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(statusColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(statusColor.opacity(0.1))
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch book.status {
        case .wantToRead: return .textTertiary
        case .currentlyReading: return .accent
        case .finished: return .success
        case .abandoned: return .textSecondary
        }
    }
}
```

### BookGridItem

A book item for grid views.

```swift
struct BookGridItem: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            BookCoverView(book: book, size: .medium)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(book.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(2)

                Text(book.author)
                    .font(.caption2)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(1)
            }

            if book.quoteCount > 0 {
                Text("\(book.quoteCount) quote\(book.quoteCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.accent)
            }
        }
        .frame(width: 100)
    }
}
```

### EmptyStateView

Consistent empty state messaging.

```swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionLabel: String?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.textTertiary)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.textPrimary)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brand)
            }
        }
        .padding(Spacing.xxl)
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    static var noBooks: EmptyStateView {
        EmptyStateView(
            icon: "books.vertical",
            title: "No Books Yet",
            message: "Add your first book by capturing its cover photo"
        )
    }

    static var noQuotes: EmptyStateView {
        EmptyStateView(
            icon: "quote.opening",
            title: "No Quotes Yet",
            message: "Capture a page with underlined text to extract quotes"
        )
    }

    static func noSearchResults(query: String) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "No matches found for \"\(query)\""
        )
    }
}
```

### LoadingOverlay

Full-screen loading state for AI processing.

```swift
struct LoadingOverlay: View {
    let message: String
    var detail: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                VStack(spacing: Spacing.sm) {
                    Text(message)
                        .font(.headline)
                        .foregroundStyle(.white)

                    if let detail = detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .padding(Spacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
    }
}
```

### AsyncButton

Button with loading state for async operations.

```swift
struct AsyncButton<Label: View>: View {
    let action: () async -> Void
    @ViewBuilder let label: () -> Label

    @State private var isLoading = false

    var body: some View {
        Button {
            Task {
                isLoading = true
                defer { isLoading = false }
                await action()
            }
        } label: {
            ZStack {
                label()
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .disabled(isLoading)
    }
}
```

---

## Screen Components

### LibraryView

```swift
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]

    @State private var searchQuery = ""
    @State private var viewMode: ViewMode = .grid
    @State private var filterStatus: ReadingStatus?

    enum ViewMode {
        case grid, list
    }

    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    EmptyStateView.noBooks
                } else {
                    content
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchQuery, prompt: "Search books")
            .toolbar { toolbarContent }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewMode {
        case .grid:
            gridView
        case .list:
            listView
        }
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: Spacing.lg)],
                spacing: Spacing.xl
            ) {
                ForEach(filteredBooks) { book in
                    NavigationLink(value: Route.bookDetail(bookID: book.id)) {
                        BookGridItem(book: book)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.lg)
        }
    }

    private var listView: some View {
        List(filteredBooks) { book in
            NavigationLink(value: Route.bookDetail(bookID: book.id)) {
                BookListRow(book: book)
            }
        }
        .listStyle(.plain)
    }

    private var filteredBooks: [Book] {
        var result = books

        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.author.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }

        return result
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("View", selection: $viewMode) {
                    Label("Grid", systemImage: "square.grid.2x2").tag(ViewMode.grid)
                    Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                }

                Divider()

                Menu("Filter by Status") {
                    Button("All") { filterStatus = nil }
                    ForEach(ReadingStatus.allCases) { status in
                        Button(status.displayName) { filterStatus = status }
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}
```

### CaptureView

Camera interface for capturing book covers and pages.

```swift
struct CaptureView: View {
    @State private var captureMode: CaptureMode = .bookCover
    @State private var capturedImage: UIImage?
    @State private var showImageReview = false

    enum CaptureMode: String, CaseIterable {
        case bookCover = "Book Cover"
        case quotePage = "Quote Page"

        var icon: String {
            switch self {
            case .bookCover: return "book.closed"
            case .quotePage: return "text.quote"
            }
        }

        var instructions: String {
            switch self {
            case .bookCover:
                return "Center the book cover in the frame"
            case .quotePage:
                return "Capture the page with your underlined passages"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview
                CameraPreviewView(capturedImage: $capturedImage)
                    .ignoresSafeArea()

                // Overlay UI
                VStack {
                    // Mode selector
                    modeSelector
                        .padding(.top, Spacing.lg)

                    Spacer()

                    // Instructions
                    Text(captureMode.instructions)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())

                    // Capture button
                    captureButton
                        .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showImageReview) {
                if let image = capturedImage {
                    ImageReviewView(image: image, mode: captureMode)
                }
            }
            .onChange(of: capturedImage) { _, newValue in
                if newValue != nil {
                    showImageReview = true
                }
            }
        }
    }

    private var modeSelector: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(CaptureMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        captureMode = mode
                    }
                } label: {
                    Label(mode.rawValue, systemImage: mode.icon)
                        .font(.subheadline)
                        .fontWeight(captureMode == mode ? .semibold : .regular)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(captureMode == mode ? .white : .white.opacity(0.3))
                        .foregroundStyle(captureMode == mode ? .black : .white)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var captureButton: some View {
        Button {
            // Trigger capture
        } label: {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 70, height: 70)

                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 80, height: 80)
            }
        }
    }
}
```

### QuoteDetailView

Full-screen quote display.

```swift
struct QuoteDetailView: View {
    let quote: Quote
    @Environment(RouterPath.self) private var router

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Featured quote card
                QuoteCardView(quote: quote, style: .featured)
                    .padding(.horizontal, Spacing.lg)

                // Metadata section
                metadataSection

                // Actions
                actionButtons
            }
            .padding(.vertical, Spacing.xl)
        }
        .background(.backgroundPrimary)
        .navigationTitle("Quote")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit", systemImage: "pencil") {
                        router.presentedSheet = .editQuote(quote: quote)
                    }
                    Button("Share", systemImage: "square.and.arrow.up") {
                        // Share action
                    }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        // Delete action
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Details")
                .font(.sectionHeader)
                .foregroundStyle(.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: Spacing.sm) {
                metadataRow(label: "Captured", value: quote.captureDate.formatted(date: .abbreviated, time: .omitted))
                metadataRow(label: "Marking", value: quote.markingType.displayName)
                if let page = quote.pageNumber {
                    metadataRow(label: "Page", value: "\(page)")
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.textSecondary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.textPrimary)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: Spacing.md) {
            Button {
                // Toggle favorite
            } label: {
                Label(
                    quote.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: quote.isFavorite ? "heart.fill" : "heart"
                )
            }
            .tint(quote.isFavorite ? .error : .brand)

            Button {
                // Add to collection
            } label: {
                Label("Add to Collection", systemImage: "folder.badge.plus")
            }
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, Spacing.lg)
    }
}
```

---

## iOS 26 Liquid Glass Adoption

Apply Liquid Glass to enhance the visual experience on iOS 26+:

```swift
// MARK: - Glass Effect Wrapper

extension View {
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        if #available(iOS 26, *) {
            self
                .background(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }

    @ViewBuilder
    func glassButton() -> some View {
        if #available(iOS 26, *) {
            self
                .buttonStyle(.glass)
        } else {
            self
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - Tab Bar Glass Effect

struct GlassTabView: View {
    @State private var selectedTab: AppTab = .library

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                tab.makeContentView()
                    .tabItem { tab.label }
                    .tag(tab)
            }
        }
        .modifier(GlassTabBarModifier())
    }
}

struct GlassTabBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .toolbarBackground(.hidden, for: .tabBar)
        } else {
            content
        }
    }
}
```

---

## Animation Guidelines

### Transitions

```swift
extension AnyTransition {
    static var quoteCard: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .opacity
        )
    }

    static var slideUp: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}
```

### Spring Animations

```swift
extension Animation {
    static var smoothSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.8)
    }

    static var quickSpring: Animation {
        .spring(response: 0.25, dampingFraction: 0.75)
    }
}
```

### Haptic Feedback

```swift
enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    // Common haptics
    static func captureSuccess() {
        notification(.success)
    }

    static func quoteAdded() {
        impact(.light)
    }

    static func favoriteToggled() {
        impact(.medium)
    }

    static func error() {
        notification(.error)
    }
}
```

---

## Accessibility

### Voice Over Support

```swift
extension QuoteCardView {
    var accessibilityContent: some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Double tap to view quote details")
    }

    private var accessibilityLabel: String {
        var parts: [String] = []
        parts.append("Quote: \(quote.text)")
        if let book = quote.book {
            parts.append("From \(book.title) by \(book.author)")
        }
        if let page = quote.pageNumber {
            parts.append("Page \(page)")
        }
        return parts.joined(separator: ". ")
    }
}
```

### Dynamic Type

All text uses system fonts that scale with Dynamic Type. Layouts should adapt gracefully to larger text sizes.

---

## File Organization

```
Components/
├── Cards/
│   ├── QuoteCardView.swift
│   └── BookCoverView.swift
├── Lists/
│   ├── BookListRow.swift
│   ├── BookGridItem.swift
│   └── QuoteListRow.swift
├── States/
│   ├── EmptyStateView.swift
│   ├── LoadingOverlay.swift
│   └── ErrorStateView.swift
├── Buttons/
│   ├── AsyncButton.swift
│   └── CaptureButton.swift
├── Input/
│   ├── SearchBar.swift
│   └── TagInput.swift
└── Design/
    ├── Colors.swift
    ├── Typography.swift
    └── Spacing.swift
```
