import SwiftUI

// MARK: - QuoteCardView

/// Beautiful, styled quote card for display throughout the app.
struct QuoteCardView: View {

    // MARK: - Properties

    let quote: Quote

    /// Whether to show book title and author
    var showBookInfo: Bool = false

    /// Card display style
    var style: CardStyle = .default

    // MARK: - Card Styles

    enum CardStyle {
        case `default`  // Standard card with full details
        case compact    // Smaller, less padding
        case expanded   // Larger text, more prominent
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Quote text
            quoteText

            // Margin note if present
            if let marginNote = quote.marginNote, !marginNote.isEmpty {
                marginNoteView(marginNote)
            }

            // Metadata row
            metadataRow

            // Book info (for cross-book views)
            if showBookInfo, let book = quote.book {
                Divider()
                bookInfoRow(book)
            }
        }
        .padding(cardPadding)
        .background(Color.quoteBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.quoteBorder, lineWidth: 1)
        }
    }

    // MARK: - Quote Text

    @ViewBuilder
    private var quoteText: some View {
        switch style {
        case .default:
            Text(quote.text)
                .font(.quoteBody)
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(4)

        case .compact:
            Text(quote.text)
                .font(.caption)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(3)

        case .expanded:
            Text(quote.text)
                .font(.quoteLarge)
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(6)
        }
    }

    // MARK: - Margin Note

    private func marginNoteView(_ note: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Image(systemName: "note.text")
                .font(.caption)
            Text(note)
                .font(.caption)
                .italic()
        }
        .foregroundStyle(.secondary)
    }

    // MARK: - Metadata Row

    private var metadataRow: some View {
        HStack {
            // Marking type badge
            MarkingTypeBadge(
                markingType: quote.markingType,
                customMarking: quote.customMarkingDefinition
            )

            // Page number
            if let page = quote.pageNumber {
                Text("p. \(page)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Favorite indicator
            if quote.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // Confidence indicator (only show if low)
            if let confidence = quote.confidence, confidence < 0.8 {
                ConfidenceIndicator(confidence: confidence)
            }
        }
    }

    // MARK: - Book Info

    private func bookInfoRow(_ book: Book) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(book.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            Text("by \(book.author)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Padding

    private var cardPadding: CGFloat {
        switch style {
        case .default: return Spacing.md
        case .compact: return Spacing.sm
        case .expanded: return Spacing.lg
        }
    }
}

// MARK: - ConfidenceIndicator

/// Compact confidence indicator with dot and percentage.
struct ConfidenceIndicator: View {

    let confidence: Double

    /// Display style
    var style: Style = .dot

    enum Style {
        case dot        // Small colored dot with percentage
        case bar        // Horizontal progress bar
        case label      // Text label only
    }

    var body: some View {
        switch style {
        case .dot:
            dotStyle
        case .bar:
            barStyle
        case .label:
            labelStyle
        }
    }

    private var dotStyle: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(confidenceColor)
                .frame(width: 6, height: 6)

            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var barStyle: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 4)

                Rectangle()
                    .fill(confidenceColor)
                    .frame(width: geometry.size.width * confidence, height: 4)
            }
            .clipShape(Capsule())
        }
        .frame(height: 4)
    }

    private var labelStyle: some View {
        Text("\(Int(confidence * 100))% confidence")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var confidenceColor: Color {
        switch confidence {
        case 0.8...: return .confidenceHigh
        case 0.5..<0.8: return .confidenceMedium
        default: return .confidenceLow
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Default Style").font(.headline)
            QuoteCardView(
                quote: previewQuote()
            )

            Text("Compact Style").font(.headline)
            QuoteCardView(
                quote: previewQuote(),
                style: .compact
            )

            Text("With Book Info").font(.headline)
            QuoteCardView(
                quote: previewQuote(),
                showBookInfo: true
            )
        }
        .padding()
    }
}

private func previewQuote() -> Quote {
    let book = Book(title: "Atomic Habits", author: "James Clear")
    let quote = Quote(
        text: "Every action you take is a vote for the type of person you wish to become.",
        book: book
    )
    quote.pageNumber = 38
    quote.marginNote = "This is key!"
    quote.confidence = 0.65
    return quote
}
