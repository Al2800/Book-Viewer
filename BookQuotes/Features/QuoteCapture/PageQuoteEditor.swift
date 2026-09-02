import SwiftUI

// MARK: - Page Quote Editor

/// Editor view for quotes extracted from a single page.
/// Shows the source image with a list of editable quotes below.
struct PageQuoteEditor: View {
    let page: PageCapture
    @Binding var quotes: [EditableQuote]
    let onAddManualQuote: () -> Void
    let imageHeight: CGFloat
    let scrollsQuotesIndependently: Bool

    @State private var showingFullImage = false
    @State private var imageScale: CGFloat = 1.0
    @State private var selectedQuoteID: UUID?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            imageSection

            Divider()
            quotesSection
        }
        .onAppear {
            if selectedQuoteID == nil {
                selectedQuoteID = quotes.first?.id
            }
        }
        .onChange(of: quotes) { _, newQuotes in
            if selectedQuoteID == nil || !newQuotes.contains(where: { $0.id == selectedQuoteID }) {
                selectedQuoteID = newQuotes.first?.id
            }
        }
    }

    private var activeQuote: EditableQuote? {
        quotes.first(where: { $0.id == selectedQuoteID }) ?? quotes.first
    }

    // MARK: - Tether Banner

    private var tetherBanner: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.gildedAccent)

            Text("Passage Illuminated on Original Page")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.gildedAccent)

            Spacer()

            Image(systemName: "link")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.gildedAccent.opacity(0.8))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 4)
        .background(
            Rectangle()
                .fill(Color.darkLinen)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.gildedAccent.opacity(0.4))
                        .frame(height: Stroke.hairline.width)
                }
        )
    }

    // MARK: - Image Section

    private var imageSection: some View {
        ZStack {
            Color.black

            if let image = page.loadFullImage() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(imageScale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale in
                                imageScale = scale
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    imageScale = max(1.0, min(imageScale, 3.0))
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            imageScale = imageScale > 1.5 ? 1.0 : 2.0
                        }
                    }
            } else if let thumbnail = page.loadThumbnail() {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay {
                        ProgressView()
                            .tint(.white)
                    }
            } else {
                ContentUnavailableView(
                    "Image Not Found",
                    systemImage: "photo.badge.exclamationmark",
                    description: Text("The source image could not be loaded")
                )
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        showingFullImage = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.65), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View full page image")
                }

                Spacer()

                HStack {
                    Spacer()
                    if imageScale > 1.0 {
                        Text("\(Int(imageScale * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(Spacing.sm)
        }
        .frame(height: imageHeight)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
        )
        .padding(Spacing.sm)
        .paperCard(cornerRadius: CornerRadius.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Source page image")
        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionPageImage)
        .fullScreenCover(isPresented: $showingFullImage) {
            FullImageViewer(page: page)
        }
    }

    // MARK: - Quotes Section

    private var quotesSection: some View {
        VStack(spacing: 0) {
            quoteListHeader
                .padding(Spacing.md)
                .background(Color.backgroundSecondary)

            if quotes.isEmpty {
                emptyState
            } else if scrollsQuotesIndependently {
                ScrollView {
                    quoteRows
                }
            } else {
                quoteRows
            }
        }
        .paperCard(cornerRadius: CornerRadius.lg)
    }

    private var quoteRows: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach($quotes) { $quote in
                QuoteEditRow(
                    quote: $quote,
                    onDelete: {
                        deleteQuote(quote)
                    }
                )
            }
        }
        .padding(Spacing.md)
    }

    private var quoteListHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if dynamicTypeSize.isAccessibilitySize {
                quoteCountLabel
                addQuoteButton
            } else {
                HStack {
                    quoteCountLabel
                    Spacer()
                    addQuoteButton
                }
            }

            if let fallbackReason = page.extractionFallbackReason {
                Label(fallbackReason.reviewMessage, systemImage: "iphone")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionFallbackNotice)
            }
        }
    }

    private var quoteCountLabel: some View {
        Label(PageQuoteEditorList(quotes: quotes).countTitle, systemImage: "text.quote")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(Color.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var addQuoteButton: some View {
        Button {
            onAddManualQuote()
        } label: {
            Label("Add", systemImage: "plus")
                .font(.caption)
                .frame(minHeight: 44)
        }
        .buttonStyle(.secondaryCompact)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "text.badge.xmark")
                .font(.system(size: 40))
                .foregroundStyle(Color.textTertiary)

            Text("No Quotes Found")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            Text("The AI didn't find any marked passages on this page. You can add quotes manually.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                onAddManualQuote()
            } label: {
                Label("Add Quote Manually", systemImage: "plus")
            }
            .glassButton()
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func deleteQuote(_ quote: EditableQuote) {
        withAnimation(.snappy) {
            var list = PageQuoteEditorList(quotes: quotes)
            list.delete(quote)
            quotes = list.quotes
        }
        HapticManager.light()
    }
}

// MARK: - Preview

#Preview("Page Quote Editor") {
    PageQuoteEditor(
        page: {
            let page = PageCapture(imagePath: "test.jpg")
            page.detectedPageNumber = 42
            return page
        }(),
        quotes: .constant([
            EditableQuote(
                pageId: UUID(),
                text: "The only way to do great work is to love what you do.",
                markingType: "underline",
                confidence: 0.95,
                pageNumber: 42
            ),
            EditableQuote(
                pageId: UUID(),
                text: "Success is not final, failure is not fatal: it is the courage to continue that counts.",
                markingType: "highlight",
                confidence: 0.82,
                pageNumber: 42,
                marginNote: "Churchill?"
            )
        ]),
        onAddManualQuote: {},
        imageHeight: 260,
        scrollsQuotesIndependently: true
    )
}
