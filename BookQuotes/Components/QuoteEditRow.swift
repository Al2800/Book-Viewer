import SwiftUI

// MARK: - Quote Edit Row

/// Row component for editing an extracted quote inline.
/// Paper vellum card with a leading confidence bar and overflow actions.
struct QuoteEditRow: View {
    @Binding var quote: EditableQuote
    let onDelete: () -> Void

    @State private var showEditor = false
    @State private var draftText = ""
    @State private var draftMarginNote = ""
    @State private var draftMarkingType = MarkingType.underline.rawValue
    @State private var markingStartsConfigurable = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
                Button {
                    openEditor()
                } label: {
                    Text(quote.text)
                        .font(.quoteBody)
                        .lineSpacing(4)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionQuoteEditButton)

                if let marginNote = quote.marginNote, !marginNote.isEmpty {
                    HStack(alignment: .top, spacing: Spacing.xs) {
                        Image(systemName: "pencil.line")
                            .font(.caption2)
                            .foregroundStyle(Color.goldFoil)
                            .padding(.top, 2)
                            .accessibilityHidden(true)

                        Text(marginNote)
                            .font(.marginScript)
                            .foregroundStyle(Color.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                metaRow

                if let tags = quote.suggestedTags, !tags.isEmpty {
                    tagStrip(tags)
                }
        }
        .padding(.leading, Spacing.md + 3)
        .padding(.vertical, Spacing.md)
        .padding(.trailing, Spacing.md)
        .background(Color.warmVellum)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Self.confidenceBarColor(for: quote.confidence))
                .frame(width: 3)
        }
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .elevation(.xs)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityIdentifier("\(AccessibilityIdentifiers.Capture.extractionQuoteSourceLabel)_\(quote.extractionSource.rawValue)")
        .sheet(isPresented: $showEditor) {
            QuoteEditorSheet(
                text: $draftText,
                marginNote: $draftMarginNote,
                markingType: $draftMarkingType,
                onSave: applyEdits
            )
        }
    }

    private var metaRow: some View {
        HStack(spacing: Spacing.sm) {
            if let pageNumber = quote.pageNumber {
                Text("p. \(pageNumber)")
                    .font(.attributionSmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)

            Menu {
                Button("Edit") {
                    openEditor()
                }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Passage actions")
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.passageActionsMenu)
        }
    }

    private func tagStrip(_ tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkle")
                    .font(.uiBadge)
                    .foregroundStyle(Color.gildedAccent)
                    .accessibilityHidden(true)

                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: Spacing.xs) {
                        Text("#\(tag)")
                            .font(.uiBadge)
                            .foregroundStyle(Color.textSecondary)

                        Button {
                            withAnimation(.snappy) {
                                quote.suggestedTags?.removeAll(where: { $0 == tag })
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.textTertiary)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(tag)")
                    }
                    .padding(.leading, Spacing.sm)
                    .padding(.trailing, Spacing.xs)
                    .frame(minHeight: 44)
                    .background(Color.backgroundSecondary, in: Capsule())
                }
            }
        }
    }

    private var accessibilitySummary: String {
        if let pageNumber = quote.pageNumber {
            return "\(quote.text), p. \(pageNumber)"
        }
        return quote.text
    }

    static func confidenceBarColor(for confidence: Double?) -> Color {
        let value = confidence ?? 0
        if value >= 0.8 { return .success }
        if value >= 0.5 { return .warning }
        return .error
    }

    private func openEditor() {
        draftText = quote.text
        draftMarginNote = quote.marginNote ?? ""
        if let type = MarkingType(rawValue: quote.markingType),
           MarkingType.configurableCases.contains(type) {
            draftMarkingType = type.rawValue
            markingStartsConfigurable = true
        } else {
            draftMarkingType = MarkingType.underline.rawValue
            markingStartsConfigurable = false
        }
        showEditor = true
    }

    private func applyEdits() {
        let trimmedText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = draftMarginNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let markingChanged = markingStartsConfigurable
            ? draftMarkingType != quote.markingType
            : draftMarkingType != MarkingType.underline.rawValue

        if trimmedText != quote.text
            || trimmedNote != (quote.marginNote ?? "")
            || markingChanged {
            quote.text = trimmedText
            quote.marginNote = trimmedNote.isEmpty ? nil : trimmedNote
            if markingChanged {
                quote.markingType = draftMarkingType
            }
            quote.isModified = true
        }
        showEditor = false
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
    let displayName: String?

    private var label: String {
        displayName ?? type.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var body: some View {
        Text(label)
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
    var customMarkingDefinitionID: UUID?
    var customMarkingDisplayName: String?
    var boundingBox: CGRect?
    var suggestedTags: [String]?

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
        extractionSource: QuoteExtractionSource? = nil,
        customMarkingDefinitionID: UUID? = nil,
        customMarkingDisplayName: String? = nil,
        boundingBox: CGRect? = nil,
        suggestedTags: [String]? = nil
    ) {
        self.id = id
        self.pageId = pageId
        self.text = text
        self.markingType = markingType
        self.confidence = confidence
        self.pageNumber = pageNumber
        self.marginNote = marginNote
        self.customMarkingDefinitionID = customMarkingDefinitionID
        self.customMarkingDisplayName = customMarkingDisplayName
        self.boundingBox = boundingBox
        self.suggestedTags = suggestedTags
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
        self.customMarkingDefinitionID = data.customMarkingDefinitionID
        self.customMarkingDisplayName = data.customMarkingDisplayName
        self.boundingBox = data.normalizedBoundingBox
        self.suggestedTags = data.suggestedTags
        self.isManual = false
        self.extractionSource = data.extractionSource
        self.isModified = false
    }

    /// Convert to ExtractedQuote for saving
    func toExtractedQuote(customMarkingDefinition: MarkingDefinition? = nil) -> ExtractedQuote {
        ExtractedQuote(
            text: text,
            markingType: parseMarkingType(),
            confidence: isManual ? nil : confidence,
            pageNumber: pageNumber,
            marginNote: marginNote,
            customMarkingDefinition: customMarkingDefinition,
            boundingBox: boundingBox,
            suggestedTags: suggestedTags
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
