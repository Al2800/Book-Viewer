import SwiftUI

// MARK: - QuoteSearchResultRow

/// Row displaying a quote search result with highlighted matches.
struct QuoteSearchResultRow: View {

    // MARK: - Properties

    let result: SearchQuoteResult
    let query: String

    /// Optional Quote model for additional context
    var quote: Quote?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Quote text with FTS5 highlighting
            Text(result.highlightedSnippet)
                .font(.quoteBody)
                .lineLimit(4)

            // Book and page context
            HStack(spacing: Spacing.xs) {
                Image(systemName: "book.closed")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                if let quote = quote, let book = quote.book {
                    Text(book.title)
                        .font(.authorNameSmall)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if let page = quote.pageNumber {
                        Text("p.\(page)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Text("Unknown book")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }

            // Margin note if present
            if let quote = quote, let note = quote.marginNote, !note.isEmpty {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            // Bottom row: marking type and confidence
            HStack {
                if let quote = quote {
                    markingBadge(for: quote)
                }

                Spacer()

                // Confidence indicator if low
                if let quote = quote, let confidence = quote.confidence, confidence < 0.7 {
                    ConfidenceDot(confidence: confidence)
                }
            }
        }
        .padding(Spacing.md)
        .paperCard(cornerRadius: CornerRadius.lg)
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.quoteResultRow)
    }

    // MARK: - Private Views

    @ViewBuilder
    private func markingBadge(for quote: Quote) -> some View {
        Text(quote.markingDisplayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.accent.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - ConfidenceDot

/// Visual indicator for AI extraction confidence.
struct ConfidenceDot: View {
    let confidence: Double

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(confidenceColor)
                .frame(width: 8, height: 8)

            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
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
    List {
        QuoteSearchResultRow(
            result: SearchQuoteResult(
                quoteId: UUID(),
                bookId: UUID(),
                snippet: "Every <mark>action</mark> you take is a <mark>vote</mark> for the type of person you wish to become.",
                rank: 1.0
            ),
            query: "action vote"
        )

        QuoteSearchResultRow(
            result: SearchQuoteResult(
                quoteId: UUID(),
                bookId: UUID(),
                snippet: "The <mark>happiness</mark> of your life depends upon the quality of your thoughts.",
                rank: 0.9
            ),
            query: "happiness"
        )
    }
}
