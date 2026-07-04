import SwiftData
import SwiftUI

// MARK: - Add Manual Quote Sheet

/// Sheet for manually adding a quote that the AI missed.
struct AddManualQuoteSheet: View {
    @Environment(\.dismiss) private var dismiss

    let pageId: UUID
    let pageNumber: Int?
    let onAdd: (EditableQuote) -> Void

    @State private var quoteText = ""
    @State private var selectedMarkingType = "underline"
    @State private var marginNote = ""
    @State private var hasAppeared = false
    @State private var quoteTextShakeTrigger = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let markingTypes = [
        "underline",
        "highlight",
        "margin_line",
        "bracket",
        "circle",
        "margin_note",
        "asterisk",
        "question_mark",
        "box"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Quote Text") {
                    TextEditor(text: $quoteText)
                        .frame(minHeight: 100)
                        .shake(trigger: quoteTextShakeTrigger)
                }

                Section("Marking Type") {
                    Picker("Type", selection: $selectedMarkingType) {
                        ForEach(markingTypes, id: \.self) { type in
                            Text(type.replacingOccurrences(of: "_", with: " ").capitalized)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Margin Note (Optional)") {
                    TextField("Any note in the margin...", text: $marginNote)
                }

                if let pageNum = pageNumber {
                    Section {
                        HStack {
                            Text("Page Number")
                            Spacer()
                            Text("\(pageNum)")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .navigationTitle("Add Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.light()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        validateAndAddQuote()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 10)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring) {
                hasAppeared = true
            }
        }
    }

    private var isQuoteTextValid: Bool {
        !quoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func validateAndAddQuote() {
        guard isQuoteTextValid else {
            quoteTextShakeTrigger += 1
            HapticManager.error()
            return
        }
        addQuote()
    }

    private func addQuote() {
        let trimmedText = quoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let quote = EditableQuote(
            pageId: pageId,
            text: trimmedText,
            markingType: selectedMarkingType,
            confidence: nil,
            pageNumber: pageNumber,
            marginNote: marginNote.isEmpty ? nil : marginNote,
            isManual: true
        )

        onAdd(quote)
        HapticManager.light()
        dismiss()
    }
}

// MARK: - Review Summary View

/// Summary view shown before final save.
struct ReviewSummaryView: View {
    let quotes: [EditableQuote]
    let book: Book

    private var quotesByPage: [(pageNumber: Int?, count: Int)] {
        Dictionary(grouping: quotes, by: \.pageNumber)
            .map { (pageNumber: $0.key, count: $0.value.count) }
            .sorted { ($0.pageNumber ?? Int.max) < ($1.pageNumber ?? Int.max) }
    }

    private var markingTypeCounts: [(type: String, count: Int)] {
        Dictionary(grouping: quotes, by: \.markingType)
            .map { (type: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(Color.brand)
                VStack(alignment: .leading) {
                    Text(book.title)
                        .font(.bookTitle)
                    Text(book.author)
                        .font(.authorName)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Divider()

            HStack {
                Image(systemName: "text.quote")
                Text("\(quotes.count) quotes to save")
                    .font(.subheadline)
            }

            if !quotesByPage.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("By Page")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)

                    ForEach(quotesByPage, id: \.pageNumber) { item in
                        HStack {
                            if let page = item.pageNumber {
                                Text("Page \(page)")
                            } else {
                                Text("Unknown page")
                            }
                            Spacer()
                            Text("\(item.count)")
                                .foregroundStyle(Color.textSecondary)
                        }
                        .font(.caption)
                    }
                }
            }

            if !markingTypeCounts.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("By Marking Type")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)

                    ForEach(markingTypeCounts, id: \.type) { item in
                        HStack {
                            Text(item.type.replacingOccurrences(of: "_", with: " ").capitalized)
                            Spacer()
                            Text("\(item.count)")
                                .foregroundStyle(Color.textSecondary)
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

// MARK: - Preview

#Preview("Extraction Review") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try? ModelContainer(
        for: Book.self,
        Quote.self,
        CaptureSession.self,
        PageCapture.self,
        configurations: config
    )

    Group {
        if let container {
            let (book, session): (Book, CaptureSession) = {
                let book = Book(title: "Atomic Habits", author: "James Clear")
                container.mainContext.insert(book)

                let session = CaptureSession(book: book)
                container.mainContext.insert(session)
                return (book, session)
            }()

            ExtractionReviewView(session: session, book: book)
                .modelContainer(container)
        } else {
            Text("Preview unavailable")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Add Manual Quote") {
    AddManualQuoteSheet(
        pageId: UUID(),
        pageNumber: 42,
        onAdd: { _ in }
    )
}
