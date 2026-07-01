# Library Search Refactor - 2026-06-14

## Scope

- Extracted search empty, no-results, and error-state presentation from `SearchResultsView.swift` into `Features/Library/SearchResultsStateViews.swift`.
- Extracted raw SQLite statement lifecycle and typed column access from `SearchDatabase.swift` into `Services/SQLiteStatement.swift`.
- Extracted FTS query normalization and prefix construction into `Services/SearchFTSQueryBuilder.swift`.
- Preserved existing search SQL, ranking, limits, search scopes, result navigation, and row presentation.

## LOC Result

- `BookQuotes/Features/Library/SearchResultsView.swift`: 353 LOC.
- `BookQuotes/Features/Library/SearchResultsStateViews.swift`: 218 LOC.
- `BookQuotes/Services/SearchDatabase.swift`: 594 LOC -> 497 LOC.
- `BookQuotes/Services/SQLiteStatement.swift`: 46 LOC.
- `BookQuotes/Services/SearchFTSQueryBuilder.swift`: 24 LOC.

## Verification

Build:

```bash
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result:

- Passed.

Focused Search database/integration/UI characterization:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/SearchDatabaseTests \
  -only-testing:BookQuotesTests/FTSQueryCorrectnessIntegrationTests \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_NoResults_ShowsEmptyState \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_Scopes_Available \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_Query_ShowsResults \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_SeededQuote_ReturnsMatch \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearchResult_TapFirstCell_NavigatesToDetail
```

Result before search edits:

- Passed.
- Runtime: `84.313` seconds.

Result after search refactor:

- Passed.
- Runtime: `78.696` seconds.

Notes:

- Xcode emitted existing Swift 6 sendability and simulator/debugger warnings.
- No tests were changed to make this pass.

## Residual Risk

- `SearchResultsView.swift` remains the highest-complexity Library feature module by proxy, although it is now below the 500 LOC target.
- `SearchDatabase.swift` is now below the 500 LOC target but still owns several related behaviours: indexing, result search, counts, suggestions, vocabulary creation, and typo correction. Further changes should be characterized around the specific behaviour being moved.
