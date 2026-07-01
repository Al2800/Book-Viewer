# Search Database SQL Catalog Refactor - 2026-06-30

## Scope

- Extracted schema, search, insert, suggestion, vocabulary, and closest-term SQL strings from `Services/SearchDatabase.swift` into `Services/SearchDatabaseSQL.swift`.
- Kept database opening, SQL execution, parameter binding calls, result mapping, index maintenance, statistics, suggestions, and typo-correction orchestration in `SearchDatabase.swift`.

## LOC Result

- `BookQuotes/Services/SearchDatabase.swift`: 497 LOC -> 399 LOC.
- `BookQuotes/Services/SearchDatabaseSQL.swift`: 98 LOC.

## Verification

Build:

```bash
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result:

- Passed.

Focused SearchDatabase tests:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/SearchDatabaseTests
```

Result before edits:

- Passed.
- Runtime: `35.599` seconds.

Result after refactor:

- Passed.
- Runtime: `31.971` seconds.

Notes:

- Xcode emitted existing Swift 6 actor-isolation and sendability warnings.
- No tests were edited for this slice.

## Residual Risk

- The existing `SearchDatabase` synchronous initializers still produce Swift 6 actor-isolation warnings when they call `openDatabase()` and `createFTSTables()`.
- That concurrency warning should be handled as its own TDD slice because it touches initialization semantics.
