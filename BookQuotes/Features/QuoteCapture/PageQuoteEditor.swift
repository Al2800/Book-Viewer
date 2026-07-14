import SwiftUI

// MARK: - Page Quote Editor

/// Editor view for quotes extracted from a single page.
/// Shows the source image with a list of editable quotes below.
struct PageQuoteEditor: View {
    let page: PageCapture
    @Binding var quotes: [EditableQuote]
    let onAddManualQuote: () -> Void

    @State private var showingFullImage = false
    @State private var imageScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // Source image section
            imageSection

            Divider()

            // Quotes list section
            quotesSection
        }
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

            // Zoom indicator
            VStack {
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
                .padding(Spacing.sm)
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
        )
        .padding(Spacing.sm)
        .paperCard(cornerRadius: CornerRadius.lg)
        .onTapGesture {
            showingFullImage = true
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            FullImageViewer(page: page)
        }
    }

    // MARK: - Quotes Section

    private var quotesSection: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Label(PageQuoteEditorList(quotes: quotes).countTitle, systemImage: "text.quote")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Button {
                        onAddManualQuote()
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.secondaryCompact)
                }

                if let fallbackReason = page.extractionFallbackReason {
                    Label(fallbackReason.reviewMessage, systemImage: "iphone")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionFallbackNotice)
                }
            }
            .padding(Spacing.md)
            .background(Color.backgroundSecondary)

            // Quote list
            if quotes.isEmpty {
                emptyState
            } else {
                ScrollView {
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
            }
        }
        .paperCard(cornerRadius: CornerRadius.lg)
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
        onAddManualQuote: {}
    )
}
