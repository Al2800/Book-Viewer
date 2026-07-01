# Library Search Services Characterization

Date: 2026-06-30

Issue: `docs/issues/030-library-search-services-refactor.md`

## Baseline Behaviour

- Library search uses a paired `SearchService` and `SearchSuggestionsService` backed by the same `SearchDatabase`.
- Changing search text fetches suggestions.
- Presenting search fetches suggestions for the current query.
- Dismissing search clears transient suggestions.
- Submitting a non-empty query stores it in recent search history.
- Accepting a suggestion stores it in recent search history.
- Pull-to-refresh still triggers the existing search-service refresh call.
- `LibraryView` still owns navigation from result IDs to live `Book`/`Quote` models.

## Characterization Used

Baseline search service tests before edits:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/SearchServiceTests \
  -only-testing:BookQuotesTests/SearchDatabaseTests
```

Result:

- Passed.
- Runtime: `32.968` seconds.

New characterization:

- `LibrarySearchServicesTests.testSearchSubmissionAndPresentationUpdateSuggestionsHistory`

## Non-Goals

- No change to search ranking, FTS query construction, search result rows, navigation destinations, search scopes, empty/no-results/error states, or search suggestions UI presentation.
