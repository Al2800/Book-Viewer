import SwiftUI
import SwiftData

// MARK: - StudioTab

/// Studio tab for creating beautifully formatted, shareable quote cards.
struct StudioTab: View {
    @Query(sort: \Quote.dateModified, order: .reverse) private var quotes: [Quote]
    @State private var selectedQuote: Quote?
    @State private var selectedTheme: StudioTheme = .darkLinen
    @State private var selectedAspect: StudioAspectRatio = .story
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                if quotes.isEmpty {
                    emptyStudioState
                } else {
                    studioContent
                }
            }
            .navigationTitle("Studio")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedQuote) { quote in
                QuoteCardStudioView(
                    quote: quote,
                    initialTheme: selectedTheme,
                    initialAspect: selectedAspect
                )
            }
        }
    }

    // MARK: - Studio Content

    private var studioContent: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Featured Quote Card Preview
                if let featured = selectedQuote ?? quotes.first {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Live Canvas")
                                .sectionHeaderStyle()
                            Spacer()
                            Button {
                                selectedQuote = featured
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "wand.and.stars")
                                    Text("Studio Mode")
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.gildedAccent)
                            }
                        }

                        QuoteCanvasCard(
                            quote: featured,
                            theme: selectedTheme,
                            aspectRatio: selectedAspect
                        )
                        .frame(maxWidth: .infinity)
                        .elevation(.md)
                        .onTapGesture {
                            selectedQuote = featured
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }

                // Theme & Aspect Controls
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Presets")
                        .sectionHeaderStyle()
                        .padding(.horizontal, Spacing.lg)

                    StudioThemePicker(
                        selectedTheme: $selectedTheme,
                        selectedAspect: $selectedAspect
                    )
                }

                // Choose from Library Quotes
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Select a Quote")
                        .sectionHeaderStyle()
                        .padding(.horizontal, Spacing.lg)

                    LazyVStack(spacing: Spacing.md) {
                        ForEach(quotes) { quote in
                            Button {
                                HapticManager.light()
                                selectedQuote = quote
                            } label: {
                                HStack(spacing: Spacing.md) {
                                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                                        Text("\u{201C}\(quote.text)\u{201D}")
                                            .font(.quoteBody)
                                            .foregroundStyle(Color.textPrimary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)

                                        if let book = quote.book {
                                            Text("— \(book.title)")
                                                .font(.caption)
                                                .foregroundStyle(Color.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Color.textTertiary)
                                }
                                .padding(Spacing.md)
                                .paperCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }
            .padding(.vertical, Spacing.lg)
        }
    }

    // MARK: - Empty State

    private var emptyStudioState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 48))
                .foregroundStyle(Color.gildedAccent)

            Text("Quote Card Studio")
                .font(.serifHeadline)
                .foregroundStyle(Color.textPrimary)

            Text("Capture or save quotes to transform them into luxury editorial cards for social sharing, wallpapers, and Notion.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .padding()
    }
}

// MARK: - QuoteCanvasCard

/// Typographic card rendering for canvas and live previews.
struct QuoteCanvasCard: View {
    let quote: Quote
    let theme: StudioTheme
    let aspectRatio: StudioAspectRatio

    private var displayFont: Font {
        if quote.text.count < 80 {
            return .serifTitleLarge
        } else if quote.text.count < 180 {
            return .quoteDisplay
        } else {
            return .quoteLarge
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Top Mark
                HStack {
                    Image(systemName: "quote.opening")
                        .font(.title2)
                        .foregroundStyle(theme.accentColor)
                    Spacer()
                }

                Text("\u{201C}\(quote.text)\u{201D}")
                    .font(displayFont)
                    .foregroundStyle(theme.textColor)
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let marginNote = quote.marginNote, !marginNote.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "pencil.line")
                            .font(.caption2)
                            .foregroundStyle(theme.accentColor)
                        Text(marginNote)
                            .font(.marginScript)
                            .foregroundStyle(theme.textColor.opacity(0.9))
                    }
                    .padding(Spacing.sm)
                    .background(theme.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                }

                Spacer(minLength: Spacing.md)

                // Attribution footer
                if let book = quote.book {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(book.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(theme.textColor)

                        HStack(spacing: Spacing.xs) {
                            Text(book.author)
                                .font(.subheadline)
                                .foregroundStyle(theme.secondaryTextColor)

                            if let page = quote.pageNumber {
                                Text("· p. \(page)")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.secondaryTextColor)
                            }
                        }
                    }
                }

                // Brand subtle footer
                HStack {
                    Text("BookQuotes Studio")
                        .font(.caption2.italic())
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.6))
                    Spacer()
                }
            }
            .padding(Spacing.xl)

            // Bookmark Ribbon
            BookmarkRibbon()
                .padding(.trailing, Spacing.lg)
                .offset(y: -2)
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(theme.cardBackground)
                .overlay {
                    LinearGradient.cardHighlight
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(theme.borderColor, lineWidth: Stroke.hairline.width)
                }
        )
    }
}

// MARK: - QuoteCardStudioView

/// Fullscreen interactive Studio mode with live canvas, controls, and export options.
struct QuoteCardStudioView: View {
    let quote: Quote
    @State var currentTheme: StudioTheme
    @State var currentAspect: StudioAspectRatio
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var toastMessage: String?
    @Environment(\.dismiss) private var dismiss

    init(quote: Quote, initialTheme: StudioTheme = .darkLinen, initialAspect: StudioAspectRatio = .story) {
        self.quote = quote
        self._currentTheme = State(initialValue: initialTheme)
        self._currentAspect = State(initialValue: initialAspect)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.md) {
                    // Live Gesture Canvas
                    QuoteCanvasView(
                        quote: quote,
                        theme: currentTheme,
                        aspectRatio: currentAspect
                    )
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)

                    // Theme and Aspect Ratio Selectors
                    StudioThemePicker(
                        selectedTheme: $currentTheme,
                        selectedAspect: $currentAspect
                    )
                    .padding(.bottom, Spacing.md)
                }

                // Toast banner
                if let toastMessage {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.black.opacity(0.85))
                            .clipShape(Capsule())
                            .padding(.bottom, Spacing.xl)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            .navigationTitle("Studio Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            shareRenderedImage()
                        } label: {
                            Label("Share Image", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            copyImage()
                        } label: {
                            Label("Copy Image", systemImage: "doc.on.doc")
                        }

                        Button {
                            Task {
                                await saveToPhotos()
                            }
                        } label: {
                            Label("Save to Photos", systemImage: "photo")
                        }

                        Divider()

                        Button {
                            exportObsidian()
                        } label: {
                            Label("Export for Obsidian", systemImage: "text.badge.star")
                        }

                        Button {
                            exportNotion()
                        } label: {
                            Label("Export for Notion", systemImage: "list.bullet.rectangle")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.gildedAccent)
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                QuoteShareSheet(items: shareItems)
            }
        }
    }

    // MARK: - Export Actions

    private func shareRenderedImage() {
        if let image = QuoteStudioExportService.shared.renderImage(quote: quote, theme: currentTheme, aspectRatio: currentAspect) {
            shareItems = [image, quote.text]
            showingShareSheet = true
        }
    }

    private func copyImage() {
        if QuoteStudioExportService.shared.copyImageToClipboard(quote: quote, theme: currentTheme, aspectRatio: currentAspect) {
            showToast("Copied card to clipboard")
        }
    }

    private func saveToPhotos() async {
        do {
            try await QuoteStudioExportService.shared.saveImageToPhotos(quote: quote, theme: currentTheme, aspectRatio: currentAspect)
            showToast("Saved to Photos")
        } catch {
            showToast("Failed to save image")
        }
    }

    private func exportObsidian() {
        let md = QuoteStudioExportService.shared.generateObsidianMarkdown(quote: quote)
        UIPasteboard.general.string = md
        HapticManager.notification(.success)
        showToast("Copied Obsidian Markdown")
    }

    private func exportNotion() {
        let md = QuoteStudioExportService.shared.generateNotionMarkdown(quote: quote)
        UIPasteboard.general.string = md
        HapticManager.notification(.success)
        showToast("Copied Notion Markdown")
    }

    private func showToast(_ message: String) {
        withAnimation(.spring()) {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring()) {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }
}
