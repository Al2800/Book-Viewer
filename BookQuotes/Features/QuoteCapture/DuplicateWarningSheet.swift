import SwiftUI
import SwiftData

// MARK: - DuplicateWarningSheet

/// Sheet displayed when a potential duplicate quote is detected.
/// Allows user to save anyway, cancel, or view the existing quote.
struct DuplicateWarningSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    /// The duplicate matches found
    let duplicates: [DuplicateDetector.DuplicateResult]

    /// The new quote text being saved
    let newQuoteText: String

    /// Book the quote is being saved to
    let book: Book?

    /// Action when user chooses to save anyway
    let onSaveAnyway: () -> Void

    /// Action when user cancels
    let onCancel: () -> Void

    // MARK: - Local State

    @State private var selectedDuplicate: DuplicateDetector.DuplicateResult?
    @State private var showingExistingQuote = false

    // MARK: - Computed Properties

    private var bestMatch: DuplicateDetector.DuplicateResult? {
        duplicates.first
    }

    private var isExactDuplicate: Bool {
        bestMatch?.isExactMatch ?? false
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    warningHeader
                    newQuotePreview
                    duplicatesSection
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Possible Duplicate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingExistingQuote) {
            if let duplicate = selectedDuplicate {
                ExistingQuoteDetailSheet(
                    quoteId: duplicate.existingQuoteId,
                    similarity: duplicate.similarityScore
                )
            }
        }
    }

    // MARK: - Warning Header

    private var warningHeader: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: isExactDuplicate ? "exclamationmark.triangle.fill" : "doc.on.doc.fill")
                .font(.system(size: 48))
                .foregroundStyle(isExactDuplicate ? .warning : .accent)

            Text(isExactDuplicate ? "Exact Duplicate Found" : "Similar Quote Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text(isExactDuplicate
                ? "This quote already exists in your library."
                : "This quote is similar to one you've already saved.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.md)
    }

    // MARK: - New Quote Preview

    private var newQuotePreview: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("New Quote", systemImage: "text.quote")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(newQuoteText)
                .font(.quoteBody)
                .lineLimit(5)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
    }

    // MARK: - Duplicates Section

    private var duplicatesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Existing \(duplicates.count == 1 ? "Quote" : "Quotes")", systemImage: "doc.text.magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(duplicates) { duplicate in
                DuplicateMatchCard(
                    duplicate: duplicate,
                    onTap: {
                        selectedDuplicate = duplicate
                        showingExistingQuote = true
                    }
                )
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.md) {
            // Cancel button (prominent for exact matches)
            if isExactDuplicate {
                Button {
                    onCancel()
                    dismiss()
                } label: {
                    Label("Don't Save", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)
            }

            // Save anyway button
            Button {
                onSaveAnyway()
                dismiss()
            } label: {
                Label(isExactDuplicate ? "Save Duplicate Anyway" : "Save Anyway", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(isExactDuplicate ? .bordered : .borderedProminent)
            .tint(isExactDuplicate ? .secondary : .accent)

            // Cancel button (less prominent for similar quotes)
            if !isExactDuplicate {
                Button {
                    onCancel()
                    dismiss()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.top, Spacing.md)
    }
}

// MARK: - DuplicateMatchCard

/// Card showing a duplicate quote match with similarity score.
private struct DuplicateMatchCard: View {
    let duplicate: DuplicateDetector.DuplicateResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    // Similarity badge
                    SimilarityBadge(score: duplicate.similarityScore, isExact: duplicate.isExactMatch)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(duplicate.existingQuoteText)
                    .font(.quoteBody)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(duplicate.isExactMatch ? Color.warning.opacity(0.1) : Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(duplicate.isExactMatch ? Color.warning.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SimilarityBadge

/// Badge showing similarity percentage.
private struct SimilarityBadge: View {
    let score: Double
    let isExact: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isExact ? "equal.circle.fill" : "percent")
                .font(.caption2)

            Text(String(format: "%.0f%% match", score * 100))
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(isExact ? Color.warning.opacity(0.2) : Color.accent.opacity(0.2))
        .foregroundStyle(isExact ? .warning : .accent)
        .clipShape(Capsule())
    }
}

// MARK: - ExistingQuoteDetailSheet

/// Sheet showing full details of an existing quote.
private struct ExistingQuoteDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let quoteId: UUID
    let similarity: Double

    @State private var quote: Quote?

    var body: some View {
        NavigationStack {
            Group {
                if let quote = quote {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            // Similarity indicator
                            HStack {
                                SimilarityBadge(score: similarity, isExact: similarity >= 0.99)
                                Spacer()
                            }

                            // Full quote text
                            Text(quote.text)
                                .font(.quoteBody)
                                .lineSpacing(6)

                            // Book info
                            if let book = quote.book {
                                Divider()
                                HStack {
                                    Image(systemName: "book.closed")
                                        .foregroundStyle(.secondary)
                                    Text(book.title)
                                        .font(.subheadline)
                                    if let pageNumber = quote.pageNumber {
                                        Text("p. \(pageNumber)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }

                            // Capture date
                            Divider()
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.secondary)
                                Text("Saved \(quote.captureDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "Quote Not Found",
                        systemImage: "doc.questionmark",
                        description: Text("The original quote could not be loaded.")
                    )
                }
            }
            .navigationTitle("Existing Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadQuote()
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func loadQuote() {
        let id = quoteId
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate<Quote> { $0.id == id }
        )
        quote = try? modelContext.fetch(descriptor).first
    }
}

// MARK: - DuplicateCheckResult

/// Observable wrapper for duplicate check results.
/// Used to trigger the warning sheet from save flows.
@MainActor
@Observable
final class DuplicateCheckResult {
    var duplicates: [DuplicateDetector.DuplicateResult] = []
    var newQuoteText: String = ""
    var book: Book?
    var showWarning: Bool = false

    /// Pending action to execute after user decision
    var pendingSaveAction: (() -> Void)?

    func present(
        duplicates: [DuplicateDetector.DuplicateResult],
        newQuoteText: String,
        book: Book?,
        onSave: @escaping () -> Void
    ) {
        self.duplicates = duplicates
        self.newQuoteText = newQuoteText
        self.book = book
        self.pendingSaveAction = onSave
        self.showWarning = true
    }

    func reset() {
        duplicates = []
        newQuoteText = ""
        book = nil
        showWarning = false
        pendingSaveAction = nil
    }
}

// MARK: - Preview

#Preview("Exact Duplicate") {
    DuplicateWarningSheet(
        duplicates: [
            .init(
                id: UUID(),
                existingQuoteId: UUID(),
                existingQuoteText: "The only way to do great work is to love what you do.",
                similarityScore: 0.99,
                isExactMatch: true
            )
        ],
        newQuoteText: "The only way to do great work is to love what you do.",
        book: nil,
        onSaveAnyway: {},
        onCancel: {}
    )
}

#Preview("Similar Quote") {
    DuplicateWarningSheet(
        duplicates: [
            .init(
                id: UUID(),
                existingQuoteId: UUID(),
                existingQuoteText: "Success is the sum of small efforts repeated day in and day out.",
                similarityScore: 0.87,
                isExactMatch: false
            ),
            .init(
                id: UUID(),
                existingQuoteId: UUID(),
                existingQuoteText: "Success comes from small efforts made consistently every day.",
                similarityScore: 0.82,
                isExactMatch: false
            )
        ],
        newQuoteText: "Success is made of small consistent efforts daily.",
        book: nil,
        onSaveAnyway: {},
        onCancel: {}
    )
}
