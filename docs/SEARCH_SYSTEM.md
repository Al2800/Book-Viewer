# Search System Guide

This document explains BookQuotes' full-text search architecture—how it works, how to use it, and how to extend it.

---

## Table of Contents

1. [Overview](#overview)
2. [Why SQLite FTS5?](#why-sqlite-fts5)
3. [Architecture](#architecture)
4. [The Search Database](#the-search-database)
5. [The Search Service](#the-search-service)
6. [Search Suggestions](#search-suggestions)
7. [Index Management](#index-management)
8. [Query Processing](#query-processing)
9. [Performance Characteristics](#performance-characteristics)
10. [Extending Search](#extending-search)

---

## Overview

BookQuotes uses **SQLite FTS5** (Full-Text Search 5) for instant-as-you-type search across quotes and books. This is separate from SwiftData—we maintain a dedicated search index that's optimized for text queries.

### Key Features

- **Instant search**: Results appear as you type (150ms debounce)
- **Relevance ranking**: Results sorted by BM25 score
- **Snippet generation**: Matching terms highlighted in context
- **Porter stemming**: "running" matches "run", "runs", "runner"
- **Prefix matching**: "atomi" matches "atomic"
- **Typo correction**: "atmoic" → "Did you mean: atomic?"

---

## Why SQLite FTS5?

We chose FTS5 over alternatives for several reasons:

| Option | Pros | Cons | Our Choice |
|--------|------|------|------------|
| **SwiftData @Query** | Simple, integrated | No full-text, slow for large datasets | ❌ |
| **Core Spotlight** | System integration | Complex, async-only, no ranking | ❌ |
| **SQLite FTS5** | Fast, flexible, ranking | Separate index | ✅ |
| **Algolia/Elasticsearch** | Powerful | Requires server, cost | ❌ |

FTS5 gives us:
- **Sub-millisecond queries** on 10,000+ quotes
- **Porter stemming** out of the box
- **BM25 ranking** for relevance
- **Snippet generation** with match highlighting
- **No network dependency**

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         View Layer                               │
│  SearchResultsView observes SearchService.results               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ @Observable
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       SearchService                              │
│  ────────────────────────────────────────────────────────────── │
│  • Debounces user input (150ms)                                 │
│  • Manages search state (isSearching, results, error)           │
│  • Provides index management API                                │
│  @MainActor @Observable class                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ actor
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SearchDatabase                              │
│  ────────────────────────────────────────────────────────────── │
│  • SQLite FTS5 virtual tables                                   │
│  • Query execution                                              │
│  • Index maintenance                                            │
│  actor (thread-safe)                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SQLite Database                               │
│  ~/Documents/search_index.sqlite                                │
│  ├── quotes_fts (virtual table)                                 │
│  ├── books_fts (virtual table)                                  │
│  └── quotes_fts_vocab (vocabulary stats)                        │
└─────────────────────────────────────────────────────────────────┘
```

### Separation from SwiftData

We maintain two data stores:

| Store | Purpose | Technology |
|-------|---------|------------|
| **SwiftData** | Primary data, relationships, persistence | ModelContainer |
| **Search Index** | Full-text search, ranking | SQLite FTS5 |

This separation means:
- Changes to SwiftData models require index updates
- The search index can be rebuilt from SwiftData
- Search is fast because it's optimized for that purpose

---

## The Search Database

### File Location

```swift
let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let dbPath = docs.appendingPathComponent("search_index.sqlite")
```

### Schema

```sql
-- Quotes full-text search table
CREATE VIRTUAL TABLE quotes_fts USING fts5(
    quote_id UNINDEXED,      -- UUID, not searchable
    book_id UNINDEXED,       -- UUID, not searchable
    text,                     -- Main quote text (searchable)
    margin_note,              -- User's margin notes (searchable)
    book_title,               -- For context in results (searchable)
    book_author,              -- For context in results (searchable)
    tokenize='porter unicode61'  -- Stemming + Unicode support
);

-- Books full-text search table
CREATE VIRTUAL TABLE books_fts USING fts5(
    book_id UNINDEXED,
    title,
    author,
    subtitle,
    tokenize='porter unicode61'
);

-- Vocabulary table for suggestions and typo detection
CREATE VIRTUAL TABLE quotes_fts_vocab USING fts5vocab(quotes_fts, row);
```

### Tokenization

The `porter unicode61` tokenizer:
- **Unicode support**: Handles international characters
- **Porter stemming**: Reduces words to stems
  - "running", "runs", "runner" → "run"
  - "atomic", "atoms" → "atom"
- **Case insensitive**: "Book" matches "book"

---

## The Search Service

`SearchService` is the main interface for search operations.

### Initialization

```swift
// In app initialization
let searchService = try SearchService()

// Inject via environment
ContentView()
    .environment(searchService)
```

### Debounced Search

The primary search method debounces input to avoid excessive queries:

```swift
func search(_ query: String, scope: SearchScope = .all) {
    // Cancel any pending search
    currentTask?.cancel()

    guard !query.isEmpty else {
        results = .empty
        return
    }

    currentTask = Task {
        // Wait 150ms for user to stop typing
        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled else { return }

        isSearching = true
        defer { isSearching = false }

        let searchResults = try await searchDB.search(query: query, scope: scope)
        self.results = searchResults
    }
}
```

### Search Scopes

```swift
enum SearchScope: String, CaseIterable {
    case all      // Search both quotes and books
    case quotes   // Only quotes
    case books    // Only books
}
```

### Search Results

```swift
struct SearchResults {
    let quotes: [SearchQuoteResult]
    let books: [SearchBookResult]
    let query: String

    static let empty = SearchResults(quotes: [], books: [], query: "")
}

struct SearchQuoteResult: Identifiable {
    let id: UUID
    let quoteId: UUID
    let bookId: UUID
    let snippet: String    // Excerpt with <mark> tags
    let rank: Double       // BM25 score (lower = more relevant)
}

struct SearchBookResult: Identifiable {
    let id: UUID
    let bookId: UUID
    let titleSnippet: String
    let authorSnippet: String
    let rank: Double
}
```

### Observable State

Views can observe search state:

```swift
struct SearchResultsView: View {
    let searchService: SearchService

    var body: some View {
        if searchService.isSearching {
            ProgressView("Searching...")
        } else if let error = searchService.lastError {
            ErrorView(error: error)
        } else if searchService.results.isEmpty {
            Text("No results")
        } else {
            List {
                Section("Books") {
                    ForEach(searchService.results.books) { ... }
                }
                Section("Quotes") {
                    ForEach(searchService.results.quotes) { ... }
                }
            }
        }
    }
}
```

---

## Search Suggestions

`SearchSuggestionsService` provides autocomplete and typo correction.

### Suggestion Types

```swift
enum SearchSuggestion: Hashable, Identifiable {
    case bookTitle(String, UUID)    // "Atomic Habits" (book)
    case author(String)             // "James Clear" (author)
    case popularTerm(String, Int)   // "habits" (15 occurrences)
    case recentSearch(String)       // Recent user search
}
```

### Getting Suggestions

```swift
// As user types "ato"
let suggestions = await suggestionsService.getSuggestions(for: "ato")
// Returns:
// - .bookTitle("Atomic Habits", uuid)
// - .popularTerm("atomic", 23)
// - .popularTerm("atoms", 5)
```

### Did-You-Mean Correction

Uses Levenshtein distance to suggest corrections:

```swift
let correction = await suggestionsService.didYouMean("atmoic habits")
// Returns: "atomic habits"
```

Implementation:

```swift
func didYouMean(_ query: String) throws -> String? {
    let terms = query.lowercased().split(separator: " ")
    var corrections: [String] = []
    var hasCorrection = false

    for term in terms {
        // Check if term exists in vocabulary
        let exists = try termExists(String(term))

        if !exists && term.count >= 4 {
            // Find closest matching term
            if let suggestion = try closestTerm(to: String(term)) {
                corrections.append(suggestion)
                hasCorrection = true
            } else {
                corrections.append(String(term))
            }
        } else {
            corrections.append(String(term))
        }
    }

    return hasCorrection ? corrections.joined(separator: " ") : nil
}
```

### Recent Searches

```swift
// Store when user submits search
suggestionsService.addToHistory(query)

// Retrieve for display
let recentSearches = suggestionsService.getRecentSearches()
// Returns: ["atomic habits", "meditation", "stoicism"]
```

---

## Index Management

### When to Index

The search index must be updated when:

1. **Quote created**: After saving a new quote
2. **Quote updated**: After editing quote text
3. **Quote deleted**: Remove from index
4. **Book created**: After saving a new book
5. **Book updated**: After editing title/author
6. **Book deleted**: Remove book and all its quotes

### Indexing Quotes

```swift
// After saving a quote
let quote = Quote(text: "...", book: book)
modelContext.insert(quote)
try modelContext.save()

// Update search index
await searchService.indexQuote(quote, book: book)
```

Implementation:

```swift
func indexQuote(_ quote: Quote, book: Book) throws {
    // Remove old entry if exists
    try execute("DELETE FROM quotes_fts WHERE quote_id = ?", params: [quote.id.uuidString])

    // Insert new entry
    try execute("""
        INSERT INTO quotes_fts (quote_id, book_id, text, margin_note, book_title, book_author)
        VALUES (?, ?, ?, ?, ?, ?)
    """, params: [
        quote.id.uuidString,
        book.id.uuidString,
        quote.text,
        quote.marginNote ?? "",
        book.title,
        book.author
    ])
}
```

### Rebuilding Index

If the index becomes corrupted or out of sync:

```swift
// Fetch all books from SwiftData
let books = try modelContext.fetch(FetchDescriptor<Book>())

// Rebuild entire index
await searchService.rebuildIndex(books: books)
```

This is also called on first launch after migration.

---

## Query Processing

### FTS5 Query Syntax

User input is transformed for FTS5:

```swift
func buildFTSQuery(_ input: String) -> String {
    let terms = input.lowercased()
        .components(separatedBy: .whitespaces)
        .filter { !$0.isEmpty }
        .map { $0.replacingOccurrences(of: "\"", with: "\"\"") }

    // Add prefix operator to last term for instant search
    // "swift program" → "swift program*"
    guard let last = terms.last else { return "" }

    if terms.count == 1 {
        return "\(last)*"
    }

    return terms.dropLast().joined(separator: " ") + " \(last)*"
}
```

| User Input | FTS5 Query | Matches |
|------------|------------|---------|
| "atomic" | `atomic*` | "atomic", "atomically" |
| "atomic habits" | `atomic habits*` | "atomic habits", "atomic habituation" |
| "the art" | `the art*` | "the art of", "the artist" |

### BM25 Ranking

Results are ranked using BM25 with custom weights:

```sql
SELECT
    quote_id,
    snippet(quotes_fts, 2, '<mark>', '</mark>', '...', 32) as snippet,
    bm25(quotes_fts, 0.0, 0.0, 1.0, 0.5, 0.5, 0.3) as rank
FROM quotes_fts
WHERE quotes_fts MATCH ?
ORDER BY rank
LIMIT 50
```

Column weights:
- `quote_id`: 0.0 (not searchable)
- `book_id`: 0.0 (not searchable)
- `text`: 1.0 (primary match importance)
- `margin_note`: 0.5
- `book_title`: 0.5
- `book_author`: 0.3

### Snippet Generation

FTS5 generates snippets with match highlighting:

```sql
snippet(quotes_fts, 2, '<mark>', '</mark>', '...', 32)
--                 ^column  ^start    ^end   ^ellipsis ^max tokens
```

Result: `"...the power of <mark>atomic</mark> habits is..."

---

## Performance Characteristics

### Benchmarks

Tested on iPhone 13 with 10,000 quotes:

| Operation | Time |
|-----------|------|
| Simple query | < 5ms |
| Complex query (3+ terms) | < 15ms |
| Index single quote | < 1ms |
| Rebuild 10,000 quotes | ~2s |

### Memory Usage

- Database file: ~1KB per 10 quotes
- In-memory during search: Minimal (SQLite handles buffering)

### Optimization Tips

1. **Limit results**: We cap at 50 quotes, 20 books
2. **Debounce input**: 150ms prevents query spam
3. **Cancel previous**: Old queries cancelled when new arrives
4. **Background indexing**: Index updates off main thread

---

## Extending Search

### Adding New Searchable Fields

To add a new field (e.g., tags):

1. **Update schema**:
```sql
ALTER TABLE quotes_fts ADD COLUMN tags;
```

2. **Update indexing**:
```swift
func indexQuote(_ quote: Quote, book: Book) throws {
    let tags = quote.tags.map { $0.name }.joined(separator: " ")
    try execute("""
        INSERT INTO quotes_fts (..., tags)
        VALUES (..., ?)
    """, params: [..., tags])
}
```

3. **Update BM25 weights**:
```sql
bm25(quotes_fts, 0.0, 0.0, 1.0, 0.5, 0.5, 0.3, 0.4)
--                                           ^tags weight
```

### Adding Filters

To add filtering (e.g., by book):

```swift
func searchInBook(_ query: String, bookId: UUID) async throws -> [SearchQuoteResult] {
    let ftsQuery = buildFTSQuery(query)

    let sql = """
        SELECT quote_id, snippet(...) as snippet, bm25(...) as rank
        FROM quotes_fts
        WHERE quotes_fts MATCH ?
        AND book_id = ?
        ORDER BY rank
        LIMIT 50
    """

    return try await searchDB.execute(sql, params: [ftsQuery, bookId.uuidString])
}
```

### Phrase Search

For exact phrase matching:

```swift
// Wrap in quotes for phrase search
let phraseQuery = "\"\(query)\""
// "atomic habits" → matches only exact phrase
```

---

## Troubleshooting

### Index Out of Sync

Symptoms: Newly added quotes don't appear in search

Solution:
```swift
// Rebuild from SwiftData
let books = try modelContext.fetch(FetchDescriptor<Book>())
await searchService.rebuildIndex(books: books)
```

### Search Returns No Results

Check:
1. Is the query too short? (single characters ignored)
2. Is the index empty? Check `indexedQuotesCount`
3. Is there a typo? Check did-you-mean suggestion

### Performance Degradation

If search becomes slow:
1. Check database file size (should be small)
2. Rebuild index to defragment
3. Verify debounce is working (not querying on every keystroke)

---

## Related Documentation

- [SERVICES.md](SERVICES.md) — SearchService and SearchDatabase details
- [DATA_MODELS.md](DATA_MODELS.md) — SwiftData models being indexed
