import SwiftUI
import SwiftData

// MARK: - ActiveFiltersBar

/// Horizontal scrolling bar showing active filter pills.
/// Displays below the search bar when filters are applied.
struct ActiveFiltersBar: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries

    @Query private var books: [Book]
    @Query private var markingDefinitions: [MarkingDefinition]

    // MARK: - Properties

    @Binding var filters: SearchFilters

    // MARK: - Body

    var body: some View {
        if filters.isActive {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    // Book filters
                    bookPills

                    // Marking type filters
                    markingTypePills

                    // Date range filter
                    dateRangePill

                    // Favorites filter
                    favoritesPill

                    // Confidence filter
                    confidencePill

                    // Clear all button
                    clearAllButton
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.xs)
            .background(Color.backgroundSecondary.opacity(0.5))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Book Pills

    @ViewBuilder
    private var bookPills: some View {
        ForEach(Array(filters.bookIds), id: \.self) { bookId in
            if let book = books.first(where: { $0.id == bookId }) {
                FilterPill(
                    label: book.title,
                    style: .book
                ) {
                    withAnimation(.smoothSpring) {
                        filters.removeBook(bookId)
                    }
                }
            }
        }
    }

    // MARK: - Marking Type Pills

    @ViewBuilder
    private var markingTypePills: some View {
        ForEach(Array(filters.markingDefinitionIds), id: \.self) { definitionId in
            if let definition = markingDefinitions.first(where: { $0.id == definitionId }) {
                FilterPill(
                    label: definition.name,
                    icon: definition.icon,
                    color: Color(definition.colorName)
                ) {
                    withAnimation(.smoothSpring) {
                        filters.removeMarkingDefinition(definitionId)
                    }
                }
            }
        }

        // Legacy marking type string filters
        ForEach(Array(filters.markingTypes), id: \.self) { markingType in
            FilterPill(
                label: markingType,
                style: .markingType
            ) {
                withAnimation(.smoothSpring) {
                    filters.removeMarkingType(markingType)
                }
            }
        }
    }

    // MARK: - Date Range Pill

    @ViewBuilder
    private var dateRangePill: some View {
        if filters.dateRange != .allTime {
            let label = {
                if filters.dateRange == .custom,
                   let start = filters.customStartDate,
                   let end = filters.customEndDate {
                    return formatDateRange(start: start, end: end)
                }
                return filters.dateRange.rawValue
            }()

            FilterPill(
                label: label,
                style: .date
            ) {
                withAnimation(.smoothSpring) {
                    filters.dateRange = .allTime
                    filters.customStartDate = nil
                    filters.customEndDate = nil
                }
            }
        }
    }

    // MARK: - Favorites Pill

    @ViewBuilder
    private var favoritesPill: some View {
        if filters.favoritesOnly {
            FilterPill(
                label: "Favorites",
                style: .favorite
            ) {
                withAnimation(.smoothSpring) {
                    filters.favoritesOnly = false
                }
            }
        }
    }

    // MARK: - Confidence Pill

    @ViewBuilder
    private var confidencePill: some View {
        if let minConfidence = filters.minConfidence {
            FilterPill(
                label: "≥\(Int(minConfidence * 100))%",
                style: .confidence
            ) {
                withAnimation(.smoothSpring) {
                    filters.minConfidence = nil
                }
            }
        }
    }

    // MARK: - Clear All Button

    private var clearAllButton: some View {
        Button {
            withAnimation(.smoothSpring) {
                filters.reset()
            }
        } label: {
            Text("Clear All")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.leading, Spacing.xs)
    }

    // MARK: - Helpers

    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - Filter Button

/// Button that shows filter count badge and opens the filters sheet.
struct FilterButton: View {
    let activeCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title3)
                .overlay(alignment: .topTrailing) {
                    if activeCount > 0 {
                        Text("\(activeCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.accentColor, in: Circle())
                            .offset(x: 6, y: -6)
                    }
                }
        }
        .accessibilityLabel("Filters")
        .accessibilityHint(activeCount > 0 ? "\(activeCount) filters active" : "No active filters")
    }
}

// MARK: - Preview

#Preview("Active Filters Bar") {
    @Previewable @State var filters = SearchFilters()

    VStack(spacing: 0) {
        // Simulated search bar
        HStack {
            Image(systemName: "magnifyingglass")
            Text("Search quotes...")
                .foregroundStyle(.secondary)
            Spacer()
            FilterButton(activeCount: filters.activeFilterCount) {}
        }
        .padding()
        .background(Color.backgroundSecondary)

        // Active filters bar
        ActiveFiltersBar(filters: $filters)

        Spacer()

        // Controls for preview
        VStack(spacing: Spacing.md) {
            Text("Toggle Filters").font(.headline)

            Toggle("Favorites Only", isOn: $filters.favoritesOnly)
            Toggle("High Confidence", isOn: Binding(
                get: { filters.minConfidence != nil },
                set: { filters.minConfidence = $0 ? 0.8 : nil }
            ))

            Picker("Date Range", selection: $filters.dateRange) {
                ForEach(SearchFilters.DateRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
        }
        .padding()
    }
}

#Preview("Filter Button") {
    HStack(spacing: 24) {
        FilterButton(activeCount: 0) {}
        FilterButton(activeCount: 1) {}
        FilterButton(activeCount: 3) {}
        FilterButton(activeCount: 9) {}
    }
    .padding()
}
