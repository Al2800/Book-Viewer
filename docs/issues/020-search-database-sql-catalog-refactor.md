# Search Database SQL Catalog Refactor

Status: `closed`

Priority: medium

## Problem

`SearchDatabase.swift` was 497 LOC and still mixed actor-owned database orchestration with large inline SQL strings for schema creation, search queries, insert statements, suggestions, vocabulary checks, and typo-correction candidates.

The actor had already gained useful seams for SQLite statement lifecycle and FTS query construction, but SQL ownership remained embedded in the main service file.

## Acceptance Criteria

- [x] Characterize SearchDatabase indexing/search/suggestion behaviour before production edits.
- [x] Keep `SearchDatabase` public API unchanged.
- [x] Preserve FTS5 table definitions, tokenizer configuration, BM25 ranking, snippets, limits, insert parameters, suggestion queries, vocabulary query, and closest-term candidate query.
- [x] Extract SQL text into a focused module that owns query/schema strings only.
- [x] Keep SQL execution, parameter binding, result mapping, index maintenance, and search orchestration in `SearchDatabase`.
- [x] Move `SearchDatabase.swift` further below 500 LOC.
- [x] Build passes after extraction.
- [x] Focused SearchDatabase tests pass after extraction.
- [x] Architecture and verification docs record module ownership, test commands, LOC delta, and residual risk.

## Outcome

2026-06-30:

- Added `BookQuotes/Services/SearchDatabaseSQL.swift`.
- Replaced inline schema/search/suggestion SQL in `SearchDatabase.swift` with references to the SQL catalog.
- Kept execution and result mapping in `SearchDatabase.swift`.

## LOC Result

- `SearchDatabase.swift`: 497 LOC -> 399 LOC.
- `SearchDatabaseSQL.swift`: 98 LOC.

## Residual Risk / Next Slice

- `SearchDatabase` still emits existing Swift 6 actor-isolation warnings from synchronous initializers calling actor-isolated setup methods.
- A future slice should address initialization/concurrency warnings separately, with tests proving default, in-memory, and path-based initialization still work.
