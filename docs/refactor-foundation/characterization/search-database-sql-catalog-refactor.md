# Search Database SQL Catalog Characterization

Date: 2026-06-30

Issue: `docs/issues/020-search-database-sql-catalog-refactor.md`

## Baseline Behaviour

This slice keeps the existing SQLite FTS5 search behaviour intact while moving SQL text out of the main actor file.

Search database behaviours:

- Quotes are indexed with quote ID, book ID, text, margin note, book title, and book author.
- Books are indexed with book ID, title, author, and subtitle.
- FTS5 uses `porter unicode61` tokenization.
- Quote search returns snippets from quote text and BM25 rank with the existing weights and limit.
- Book search returns title/author snippets and BM25 rank with the existing weights and limit.
- Scope filtering still searches quotes only, books only, or both.
- Index maintenance still deletes old rows before insert.
- Removing a book still removes both book rows and quote rows for that book.
- Rebuild still clears both indexes and re-indexes books and quotes.
- Counts still read from the FTS tables.
- Title, author, and popular-term suggestions still use the same prefix/vocabulary queries.
- Term existence, closest-term candidates, and did-you-mean correction still use the same vocabulary table.

## Characterization Used

Focused SearchDatabase baseline:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/SearchDatabaseTests
```

Result before edits:

- Passed.
- Runtime: `35.599` seconds.

## Extracted Module

- `SearchDatabaseSQL.swift`: FTS table creation SQL, vocabulary table SQL, quote/book search SQL, insert SQL, suggestion SQL, term-existence SQL, and closest-term candidate SQL.

## Non-Goals

- No change to public `SearchDatabase` methods.
- No change to FTS query normalization; that remains in `SearchFTSQueryBuilder.swift`.
- No change to SQLite statement lifecycle; that remains in `SQLiteStatement.swift`.
- No change to indexing semantics, ranking weights, snippets, or limits.
- No test edits to make the refactor pass.
