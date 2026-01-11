import SwiftUI

// MARK: - HighlightedText

/// Text component that highlights search query terms within text.
/// Automatically extracts context around the first match.
struct HighlightedText: View {

    // MARK: - Properties

    let text: String
    let query: String
    var maxLength: Int = 200
    var highlightColor: Color? = nil
    var textColor: Color = .textPrimary
    var font: Font = .body

    // MARK: - Body

    var body: some View {
        Text(buildAttributedString())
    }

    // MARK: - Private Methods

    private var resolvedHighlightColor: Color {
        highlightColor ?? Color.accent.opacity(0.2)
    }

    private func buildAttributedString() -> AttributedString {
        guard !text.isEmpty, !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            var attributed = AttributedString(truncatedText(text, maxLength: maxLength))
            attributed.foregroundColor = textColor
            attributed.font = font
            return attributed
        }

        let lowerText = text.lowercased()
        let queryTerms = query
            .lowercased()
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count >= 2 }

        guard !queryTerms.isEmpty else {
            var attributed = AttributedString(truncatedText(text, maxLength: maxLength))
            attributed.foregroundColor = textColor
            attributed.font = font
            return attributed
        }

        // Find best match position
        let bestStart = findBestStartPosition(text: lowerText, terms: queryTerms)

        // Extract context window around match
        let snippet = extractSnippet(from: text, startOffset: bestStart, maxLength: maxLength)

        // Build attributed string with highlights
        return highlightTerms(in: snippet, terms: queryTerms)
    }

    private func findBestStartPosition(text: String, terms: [String]) -> Int {
        // Find first term match
        guard let firstTerm = terms.first,
              let range = text.range(of: firstTerm) else {
            return 0
        }

        let matchPosition = text.distance(from: text.startIndex, to: range.lowerBound)
        // Start 30 chars before match for context
        return max(0, matchPosition - 30)
    }

    private func extractSnippet(from text: String, startOffset: Int, maxLength: Int) -> String {
        guard text.count > maxLength else {
            return text
        }

        let safeStart = min(startOffset, max(0, text.count - maxLength))
        let startIndex = text.index(text.startIndex, offsetBy: safeStart)
        let endOffset = min(safeStart + maxLength, text.count)
        let endIndex = text.index(text.startIndex, offsetBy: endOffset)

        var snippet = String(text[startIndex..<endIndex])

        // Add ellipsis for truncation
        if safeStart > 0 {
            snippet = "..." + snippet
        }
        if endOffset < text.count {
            snippet = snippet + "..."
        }

        return snippet
    }

    private func highlightTerms(in snippet: String, terms: [String]) -> AttributedString {
        var attributed = AttributedString(snippet)
        attributed.foregroundColor = textColor
        attributed.font = font

        for term in terms {
            var searchStart = attributed.startIndex
            while searchStart < attributed.endIndex,
                  let range = attributed[searchStart...].range(of: term, options: .caseInsensitive) {
                attributed[range].backgroundColor = resolvedHighlightColor
                attributed[range].foregroundColor = textColor
                attributed[range].font = font.weight(.semibold)
                searchStart = range.upperBound
            }
        }

        return attributed
    }

    private func truncatedText(_ text: String, maxLength: Int) -> String {
        guard text.count > maxLength else { return text }
        let endIndex = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[..<endIndex]) + "..."
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HighlightedText(
            text: "Every action you take is a vote for the type of person you wish to become.",
            query: "action vote"
        )

        HighlightedText(
            text: "The quick brown fox jumps over the lazy dog. This is a longer text that should be truncated somewhere in the middle to show context around the match.",
            query: "lazy dog",
            maxLength: 80
        )

        HighlightedText(
            text: "No match here",
            query: "xyz"
        )
    }
    .padding()
}
