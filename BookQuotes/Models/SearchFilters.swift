import Foundation

// MARK: - SearchFilters

/// Filters for narrowing down search results.
/// Supports filtering by books, marking types, date range, favorites, and confidence.
struct SearchFilters: Equatable, Sendable {
    // MARK: - Properties

    /// Filter to specific books (empty means all books)
    var bookIds: Set<UUID> = []

    /// Filter to specific marking types by name (empty means all types)
    var markingTypes: Set<String> = []

    /// Filter to specific custom marking definitions by ID (empty means all)
    var markingDefinitionIds: Set<UUID> = []

    /// Date range for filtering
    var dateRange: DateRange = .allTime

    /// Custom date range (used when dateRange == .custom)
    var customStartDate: Date?
    var customEndDate: Date?

    /// Show only favorites
    var favoritesOnly: Bool = false

    /// Minimum confidence threshold (nil means no filter)
    var minConfidence: Double?

    // MARK: - Date Range

    enum DateRange: String, CaseIterable, Sendable {
        case allTime = "All Time"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisYear = "This Year"
        case custom = "Custom"

        var dateInterval: DateInterval? {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .allTime:
                return nil
            case .today:
                return calendar.dateInterval(of: .day, for: now)
            case .thisWeek:
                return calendar.dateInterval(of: .weekOfYear, for: now)
            case .thisMonth:
                return calendar.dateInterval(of: .month, for: now)
            case .thisYear:
                return calendar.dateInterval(of: .year, for: now)
            case .custom:
                return nil // Handled separately via customStartDate/customEndDate
            }
        }

        var systemImage: String {
            switch self {
            case .allTime: return "infinity"
            case .today: return "sun.max"
            case .thisWeek: return "calendar.badge.clock"
            case .thisMonth: return "calendar"
            case .thisYear: return "calendar.badge.plus"
            case .custom: return "calendar.badge.exclamationmark"
            }
        }
    }

    // MARK: - Computed Properties

    /// Whether any filter is active
    var isActive: Bool {
        !bookIds.isEmpty ||
        !markingTypes.isEmpty ||
        !markingDefinitionIds.isEmpty ||
        dateRange != .allTime ||
        favoritesOnly ||
        hasMinConfidence
    }

    /// Count of active filter categories
    var activeFilterCount: Int {
        var count = 0
        if !bookIds.isEmpty { count += 1 }
        if !markingTypes.isEmpty || !markingDefinitionIds.isEmpty { count += 1 }
        if dateRange != .allTime { count += 1 }
        if favoritesOnly { count += 1 }
        if hasMinConfidence { count += 1 }
        return count
    }

    /// Total individual selections across all filter types
    var totalSelections: Int {
        bookIds.count +
        markingTypes.count +
        markingDefinitionIds.count +
        (dateRange != .allTime ? 1 : 0) +
        (favoritesOnly ? 1 : 0) +
        (hasMinConfidence ? 1 : 0)
    }

    private var hasMinConfidence: Bool {
        minConfidence.map { _ in true } ?? false
    }

    /// The effective date interval for filtering
    var effectiveDateInterval: DateInterval? {
        if dateRange == .custom {
            guard let start = customStartDate, let end = customEndDate else {
                return nil
            }
            return DateInterval(start: start, end: end)
        }
        return dateRange.dateInterval
    }

    // MARK: - Methods

    /// Reset all filters to defaults
    mutating func reset() {
        self = SearchFilters()
    }

    /// Remove a specific book from the filter
    mutating func removeBook(_ bookId: UUID) {
        bookIds.remove(bookId)
    }

    /// Remove a specific marking type from the filter
    mutating func removeMarkingType(_ type: String) {
        markingTypes.remove(type)
    }

    /// Add a book to the filter
    mutating func addBook(_ bookId: UUID) {
        bookIds.insert(bookId)
    }

    /// Add a marking type to the filter
    mutating func addMarkingType(_ type: String) {
        markingTypes.insert(type)
    }

    /// Toggle a book in the filter
    mutating func toggleBook(_ bookId: UUID) {
        if bookIds.contains(bookId) {
            bookIds.remove(bookId)
        } else {
            bookIds.insert(bookId)
        }
    }

    /// Toggle a marking type in the filter
    mutating func toggleMarkingType(_ type: String) {
        if markingTypes.contains(type) {
            markingTypes.remove(type)
        } else {
            markingTypes.insert(type)
        }
    }
}

// MARK: - Filter Application

extension SearchFilters {
    /// Check if a quote passes all active filters
    func matches(
        quote: Quote,
        book: Book?
    ) -> Bool {
        // Book filter
        if !bookIds.isEmpty {
            guard let bookId = book?.id, bookIds.contains(bookId) else {
                return false
            }
        }

        // Marking type filter (legacy enum-based)
        if !markingTypes.isEmpty {
            let quoteMarkingType = quote.markingType.displayName
            if !markingTypes.contains(quoteMarkingType) {
                return false
            }
        }

        // Custom marking definition filter (UUID-based)
        if !markingDefinitionIds.isEmpty {
            guard let definitionId = quote.customMarkingDefinition?.id,
                  markingDefinitionIds.contains(definitionId) else {
                return false
            }
        }

        // Date filter
        if let dateInterval = effectiveDateInterval {
            if !dateInterval.contains(quote.captureDate) {
                return false
            }
        }

        // Favorites filter
        if favoritesOnly && !quote.isFavorite {
            return false
        }

        // Confidence filter
        if let minConf = minConfidence {
            let quoteConfidence = quote.confidence ?? 1.0
            if quoteConfidence < minConf {
                return false
            }
        }

        return true
    }

    /// Convenience method for filtering arrays of quotes
    func filter(quotes: [Quote], books: [Book]) -> [Quote] {
        guard isActive else { return quotes }

        let bookMap = Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0) })
        return quotes.filter { quote in
            let book = quote.book ?? bookMap[quote.book?.id ?? UUID()]
            return matches(quote: quote, book: book)
        }
    }
}

// MARK: - Codable

extension SearchFilters: Codable {
    enum CodingKeys: String, CodingKey {
        case bookIds
        case markingTypes
        case markingDefinitionIds
        case dateRange
        case customStartDate
        case customEndDate
        case favoritesOnly
        case minConfidence
    }
}

extension SearchFilters.DateRange: Codable {}

// MARK: - Marking Definition Helpers

extension SearchFilters {
    /// Add a marking definition to the filter
    mutating func addMarkingDefinition(_ id: UUID) {
        markingDefinitionIds.insert(id)
    }

    /// Remove a marking definition from the filter
    mutating func removeMarkingDefinition(_ id: UUID) {
        markingDefinitionIds.remove(id)
    }

    /// Toggle a marking definition in the filter
    mutating func toggleMarkingDefinition(_ id: UUID) {
        if markingDefinitionIds.contains(id) {
            markingDefinitionIds.remove(id)
        } else {
            markingDefinitionIds.insert(id)
        }
    }
}
