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

    private var studioContent: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
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
                        .aspectRatio(selectedAspect.ratioValue, contentMode: .fit)
                        .frame(maxWidth: 280, maxHeight: 260)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .elevation(.md)
                        .onTapGesture {
                            selectedQuote = featured
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Presets")
                        .sectionHeaderStyle()
                        .padding(.horizontal, Spacing.lg)

                    StudioThemePicker(
                        selectedTheme: $selectedTheme,
                        selectedAspect: $selectedAspect
                    )
                }

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

    private var textLength: Int {
        quote.text.count
    }

    private var quoteFontSize: CGFloat {
        switch aspectRatio {
        case .story:
            if textLength < 70 { return 24 }
            if textLength < 150 { return 19 }
            if textLength < 260 { return 15 }
            return 13
        case .square:
            if textLength < 70 { return 20 }
            if textLength < 140 { return 16 }
            if textLength < 240 { return 13 }
            return 11.5
        case .portrait:
            if textLength < 70 { return 22 }
            if textLength < 140 { return 17 }
            if textLength < 250 { return 14 }
            return 12
        }
    }

    private var quoteLineSpacing: CGFloat {
        max(3, quoteFontSize * 0.28)
    }

    private var cardPadding: CGFloat {
        switch aspectRatio {
        case .story: return Spacing.lg
        case .square, .portrait: return Spacing.md
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "quote.opening")
                        .font(.system(size: max(14, quoteFontSize * 0.9), weight: .semibold))
                        .foregroundStyle(theme.accentColor)
                    Spacer()
                }

                Spacer(minLength: 2)

                Text("\u{201C}\(quote.text)\u{201D}")
                    .font(.system(size: quoteFontSize, weight: .regular, design: .serif))
                    .foregroundStyle(theme.textColor)
                    .lineSpacing(quoteLineSpacing)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)

                if let marginNote = quote.marginNote, !marginNote.isEmpty {
                    HStack(alignment: .top, spacing: Spacing.xs) {
                        Image(systemName: "pencil.line")
                            .font(.system(size: 10))
                            .foregroundStyle(theme.accentColor)
                            .padding(.top, 2)
                        Text(marginNote)
                            .font(.system(size: max(11, quoteFontSize * 0.75), weight: .regular, design: .serif).italic())
                            .foregroundStyle(theme.textColor.opacity(0.9))
                            .lineLimit(2)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(theme.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs))
                    .padding(.top, 2)
                }

                Spacer(minLength: 2)

                if let book = quote.book {
                    HStack(alignment: .center, spacing: Spacing.sm) {
                        miniBookCoverBadge(book: book)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(book.title)
                                .font(.system(size: max(11, quoteFontSize * 0.7), weight: .semibold, design: .serif))
                                .foregroundStyle(theme.textColor)
                                .lineLimit(1)

                            HStack(spacing: Spacing.xs) {
                                Text(book.author)
                                    .font(.system(size: max(9.5, quoteFontSize * 0.6), design: .serif))
                                    .foregroundStyle(theme.secondaryTextColor)
                                    .lineLimit(1)

                                if let page = quote.pageNumber {
                                    Text("· p. \(page)")
                                        .font(.system(size: max(9.5, quoteFontSize * 0.6), design: .serif))
                                        .foregroundStyle(theme.secondaryTextColor)
                                }
                            }
                        }
                    }
                }

                HStack {
                    Text("BookQuotes Studio")
                        .font(.system(size: 8.5, weight: .regular).italic())
                        .foregroundStyle(theme.secondaryTextColor.opacity(0.6))
                    Spacer()
                }
            }
            .padding(cardPadding)

            BookmarkRibbon()
                .padding(.trailing, Spacing.md)
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
        .clipped()
    }

    @ViewBuilder
    private func miniBookCoverBadge(book: Book) -> some View {
        if let coverData = book.coverThumbnailData ?? book.coverFullData,
           let uiImage = UIImage(data: coverData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 18, height: 26)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                }
                .shadow(color: Color.black.opacity(0.15), radius: 1, y: 1)
        } else {
            let theme = ClothboundJacketTheme.forBook(book)
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.baseColor)
                .frame(width: 18, height: 26)
                .overlay {
                    Text("❖")
                        .font(.system(size: 6))
                        .foregroundStyle(theme.foilGradient)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(theme.foilBorderColor.opacity(0.6), lineWidth: 0.5)
                }
                .shadow(color: Color.black.opacity(0.15), radius: 1, y: 1)
        }
    }
}

// MARK: - QuoteCardStudioView

/// Fullscreen interactive Studio mode with live canvas, controls, and export options.
struct QuoteCardStudioView: View {
    let quote: Quote
    @State var currentTheme: StudioTheme
    @State var currentAspect: StudioAspectRatio
    @State private var canvasTransform: StudioCanvasTransform = .identity
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
                    QuoteCanvasView(
                        quote: quote,
                        theme: currentTheme,
                        aspectRatio: currentAspect,
                        transform: $canvasTransform
                    )
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)

                    StudioThemePicker(
                        selectedTheme: $currentTheme,
                        selectedAspect: $currentAspect
                    )
                    .padding(.bottom, Spacing.md)
                }

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
            .onChange(of: currentAspect) { _, _ in
                canvasTransform = .identity
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

    private func shareRenderedImage() {
        if let image = QuoteStudioExportService.shared.renderImage(
            quote: quote,
            theme: currentTheme,
            aspectRatio: currentAspect,
            transform: canvasTransform
        ) {
            shareItems = [image, quote.text]
            showingShareSheet = true
        }
    }

    private func copyImage() {
        if QuoteStudioExportService.shared.copyImageToClipboard(
            quote: quote,
            theme: currentTheme,
            aspectRatio: currentAspect,
            transform: canvasTransform
        ) {
            showToast("Copied card to clipboard")
        }
    }

    private func saveToPhotos() async {
        do {
            try await QuoteStudioExportService.shared.saveImageToPhotos(
                quote: quote,
                theme: currentTheme,
                aspectRatio: currentAspect,
                transform: canvasTransform
            )
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
