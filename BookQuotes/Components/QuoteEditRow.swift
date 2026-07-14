import SwiftUI

// MARK: - Quote Edit Row

/// Row component for editing an extracted quote inline.
/// Shows confidence indicator, text editor, and delete option.
struct QuoteEditRow: View {
    @Binding var quote: EditableQuote
    let onDelete: () -> Void

    @State private var showEditor = false
    @State private var draftText = ""
    @State private var draftMarginNote = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header with confidence and marking type
            HStack {
                ConfidenceBadge(confidence: quote.confidence)

                MarkingTypeStringBadge(type: quote.markingType)

                ExtractionSourceBadge(source: quote.extractionSource)

                Spacer()

                if let pageNumber = quote.pageNumber {
                    Text("p. \(pageNumber)")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }

                Button {
                    openEditor()
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionQuoteEditButton)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(Color.error)
                }
                .buttonStyle(.plain)
            }

            // Quote text editor
            Text(quote.text)
                .font(.quoteBody)
                .lineLimit(3)
                .foregroundStyle(Color.textPrimary)
                .textSelection(.enabled)
                .onTapGesture {
                    openEditor()
                }

            Text("Tap to edit or select text")
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)

            // Margin note if present
        if let marginNote = quote.marginNote, !marginNote.isEmpty {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "note.text")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)

                    Text(marginNote)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .italic()
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.md)
        .paperCard(cornerRadius: CornerRadius.md)
        .sheet(isPresented: $showEditor) {
            QuoteEditorSheet(
                text: $draftText,
                marginNote: $draftMarginNote,
                onSave: applyEdits
            )
        }
    }

    private func openEditor() {
        draftText = quote.text
        draftMarginNote = quote.marginNote ?? ""
        showEditor = true
    }

    private func applyEdits() {
        let trimmedText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = draftMarginNote.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedText != quote.text || trimmedNote != (quote.marginNote ?? "") {
            quote.text = trimmedText
            quote.marginNote = trimmedNote.isEmpty ? nil : trimmedNote
            quote.isModified = true
        }
        showEditor = false
    }
}

private struct ExtractionSourceBadge: View {
    let source: QuoteExtractionSource

    var body: some View {
        Label(source.reviewLabel, systemImage: source.reviewSymbol)
            .font(.caption2)
            .foregroundStyle(Color.textSecondary)
            .accessibilityIdentifier("\(AccessibilityIdentifiers.Capture.extractionQuoteSourceLabel)_\(source.rawValue)")
            .accessibilityLabel("Extraction source: \(source.reviewLabel)")
    }
}

// MARK: - Quote Editor Sheet

private struct QuoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    @Binding var marginNote: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                TextEditor(text: $text)
                    .font(.quoteBody)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 180)
                    .fieldChrome(minHeight: 180)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionQuoteTextEditor)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Margin note (optional)")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    TextField("Add a note…", text: $marginNote, axis: .vertical)
                        .textFieldStyle(.plain)
                        .fieldChrome(minHeight: 56)
                        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionQuoteMarginNoteField)
                }
            }
            .padding(Spacing.md)
            .background(Color.backgroundPrimary)
            .navigationTitle("Edit Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Confidence Badge

/// Small badge showing AI confidence level with color coding.
struct ConfidenceBadge: View {
    let confidence: Double?

    private var displayConfidence: Double {
        confidence ?? 0
    }

    private var color: Color {
        guard let conf = confidence else { return .textTertiary }
        if conf >= 0.9 {
            return .success
        } else if conf >= 0.7 {
            return .accent
        } else if conf >= 0.5 {
            return .warning
        } else {
            return .error
        }
    }

    private var label: String {
        guard let conf = confidence else { return "?" }
        return String(format: "%.0f%%", conf * 100)
    }

    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Marking Type String Badge

/// Simple badge showing marking type from string (for review screen).
struct MarkingTypeStringBadge: View {
    let type: String

    var body: some View {
        Text(type.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(Color.textSecondary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(Color.backgroundTertiary)
            .clipShape(Capsule())
    }
}

// MARK: - Editable Quote

/// Mutable wrapper for an extracted quote during review.
struct EditableQuote: Identifiable, Equatable {
    let id: UUID
    let pageId: UUID
    var text: String
    var markingType: String
    var confidence: Double?
    var pageNumber: Int?
    var marginNote: String?

    /// Whether this quote was added manually by the user
    var isManual: Bool

    /// Where this quote candidate came from before review.
    var extractionSource: QuoteExtractionSource

    /// Whether the user has edited this quote
    var isModified: Bool

    init(
        id: UUID = UUID(),
        pageId: UUID,
        text: String,
        markingType: String,
        confidence: Double? = nil,
        pageNumber: Int? = nil,
        marginNote: String? = nil,
        isManual: Bool = false,
        extractionSource: QuoteExtractionSource? = nil
    ) {
        self.id = id
        self.pageId = pageId
        self.text = text
        self.markingType = markingType
        self.confidence = confidence
        self.pageNumber = pageNumber
        self.marginNote = marginNote
        self.isManual = isManual
        self.extractionSource = extractionSource ?? (isManual ? .manual : .unknown)
        self.isModified = false
    }

    /// Create from ExtractedQuoteData
    init(from data: ExtractedQuoteData, pageId: UUID) {
        self.id = UUID()
        self.pageId = pageId
        self.text = data.text
        self.markingType = data.markingType
        self.confidence = data.confidence
        self.pageNumber = data.pageNumber
        self.marginNote = data.marginNote
        self.isManual = false
        self.extractionSource = data.extractionSource
        self.isModified = false
    }

    /// Convert to ExtractedQuote for saving
    func toExtractedQuote() -> ExtractedQuote {
        ExtractedQuote(
            text: text,
            markingType: parseMarkingType(),
            confidence: isManual ? nil : confidence,
            pageNumber: pageNumber,
            marginNote: marginNote
        )
    }

    private func parseMarkingType() -> MarkingType {
        let normalized = markingType.lowercased().replacingOccurrences(of: "_", with: " ")

        switch normalized {
        case "underline", "single underline":
            return .underline
        case "double underline":
            return .doubleUnderline
        case "highlight", "highlighted":
            return .highlight
        case "margin line", "vertical line", "sidebar":
            return .marginLine
        case "bracket", "brackets", "braces":
            return .bracket
        case "margin note", "note", "annotation":
            return .marginNote
        case "mixed":
            return .mixed
        default:
            // Map unrecognized types to closest match
            if normalized.contains("underline") {
                return .underline
            } else if normalized.contains("highlight") {
                return .highlight
            } else if normalized.contains("margin") && normalized.contains("note") {
                return .marginNote
            } else if normalized.contains("margin") {
                return .marginLine
            } else if normalized.contains("bracket") {
                return .bracket
            }
            return .mixed  // Default to mixed for unrecognized types
        }
    }
}

// MARK: - Preview

#Preview("Quote Edit Row - High Confidence") {
    VStack {
        QuoteEditRow(
            quote: .constant(EditableQuote(
                pageId: UUID(),
                text: "The only way to do great work is to love what you do.",
                markingType: "underline",
                confidence: 0.95,
                pageNumber: 42
            )),
            onDelete: {}
        )
    }
    .padding()
}

#Preview("Quote Edit Row - Low Confidence") {
    VStack {
        QuoteEditRow(
            quote: .constant(EditableQuote(
                pageId: UUID(),
                text: "Success is the sum of small efforts, repeated day in and day out.",
                markingType: "highlight",
                confidence: 0.62,
                pageNumber: 15,
                marginNote: "Key insight!"
            )),
            onDelete: {}
        )
    }
    .padding()
}
