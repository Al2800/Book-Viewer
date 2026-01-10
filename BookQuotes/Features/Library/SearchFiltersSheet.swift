import SwiftUI
import SwiftData

// MARK: - SearchFiltersSheet

/// Sheet for selecting search filters by book, marking type, date, etc.
struct SearchFiltersSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries

    @Query(sort: \Book.title) private var books: [Book]
    @Query(sort: \MarkingDefinition.sortOrder) private var markingDefinitions: [MarkingDefinition]

    // MARK: - Properties

    @Binding var filters: SearchFilters

    // MARK: - Local State

    @State private var showingCustomDatePicker = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                booksSection
                markingTypesSection
                dateRangeSection
                otherFiltersSection
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        filters.reset()
                    }
                    .disabled(!filters.isActive)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCustomDatePicker) {
            CustomDateRangePicker(
                startDate: $filters.customStartDate,
                endDate: $filters.customEndDate
            )
        }
    }

    // MARK: - Books Section

    private var booksSection: some View {
        Section {
            if books.isEmpty {
                Text("No books in library")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(books) { book in
                    BookFilterRow(
                        book: book,
                        isSelected: filters.bookIds.contains(book.id)
                    ) {
                        filters.toggleBook(book.id)
                    }
                }
            }
        } header: {
            HStack {
                Text("Books")
                Spacer()
                if !filters.bookIds.isEmpty {
                    Text("\(filters.bookIds.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Marking Types Section

    private var markingTypesSection: some View {
        Section {
            let enabledDefinitions = markingDefinitions.filter { $0.isEnabled }

            if enabledDefinitions.isEmpty {
                Text("No marking types defined")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(enabledDefinitions) { definition in
                    MarkingFilterRow(
                        definition: definition,
                        isSelected: filters.markingDefinitionIds.contains(definition.id)
                    ) {
                        filters.toggleMarkingDefinition(definition.id)
                    }
                }
            }
        } header: {
            HStack {
                Text("Marking Types")
                Spacer()
                if !filters.markingDefinitionIds.isEmpty {
                    Text("\(filters.markingDefinitionIds.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        Section("Date Added") {
            Picker("Time Range", selection: $filters.dateRange) {
                ForEach(SearchFilters.DateRange.allCases, id: \.self) { range in
                    Label(range.rawValue, systemImage: range.systemImage)
                        .tag(range)
                }
            }
            .pickerStyle(.menu)

            if filters.dateRange == .custom {
                Button {
                    showingCustomDatePicker = true
                } label: {
                    HStack {
                        Text("Custom Range")
                        Spacer()
                        if let start = filters.customStartDate,
                           let end = filters.customEndDate {
                            Text(formatDateRange(start: start, end: end))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Select dates")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Other Filters Section

    private var otherFiltersSection: some View {
        Section("Other") {
            Toggle(isOn: $filters.favoritesOnly) {
                Label("Favorites Only", systemImage: "star.fill")
            }

            Toggle(isOn: highConfidenceBinding) {
                Label("High Confidence Only", systemImage: "checkmark.seal.fill")
            }

            if filters.minConfidence != nil {
                HStack {
                    Text("Minimum")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int((filters.minConfidence ?? 0) * 100))%")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
    }

    // MARK: - Helpers

    private var highConfidenceBinding: Binding<Bool> {
        Binding(
            get: { filters.minConfidence != nil },
            set: { filters.minConfidence = $0 ? 0.8 : nil }
        )
    }

    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - BookFilterRow

private struct BookFilterRow: View {
    let book: Book
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                // Cover thumbnail
                if let imageData = book.coverThumbnailData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 30, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                } else {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.backgroundSecondary)
                        .frame(width: 30, height: 40)
                        .overlay {
                            Image(systemName: "book.closed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.subheadline)
                        .lineLimit(1)
                    Text(book.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .accent : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MarkingFilterRow

private struct MarkingFilterRow: View {
    let definition: MarkingDefinition
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: definition.icon)
                    .foregroundStyle(Color(definition.colorName))
                    .frame(width: 24)

                Text(definition.name)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .accent : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CustomDateRangePicker

private struct CustomDateRangePicker: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var startDate: Date?
    @Binding var endDate: Date?

    @State private var localStart: Date = Date()
    @State private var localEnd: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "Start Date",
                    selection: $localStart,
                    in: ...Date(),
                    displayedComponents: .date
                )

                DatePicker(
                    "End Date",
                    selection: $localEnd,
                    in: localStart...Date(),
                    displayedComponents: .date
                )
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        startDate = localStart
                        endDate = localEnd
                        dismiss()
                    }
                }
            }
            .onAppear {
                localStart = startDate ?? Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                localEnd = endDate ?? Date()
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var filters = SearchFilters()

    SearchFiltersSheet(filters: $filters)
}
