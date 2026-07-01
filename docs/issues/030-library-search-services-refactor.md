# Issue 030: Library Search Services Refactor

Status: closed

## Problem

`LibraryView` still owned search-service bootstrapping and suggestions side effects directly: creating `SearchDatabase`, pairing `SearchService` and `SearchSuggestionsService`, updating suggestions when search text changes, saving submitted search history, accepting suggestions, clearing suggestions when search closes, and triggering refresh reindexing.

That logic is small in LOC but high in coordination risk because future Library search work needs to know which services share the same database and which user interactions mutate suggestion history.

## Acceptance Criteria

- Characterize the Library search-service seam before production edits.
- Add a module that owns paired search and suggestions services behind a small interface.
- Preserve submitted search history, active-search suggestion loading, inactive-search suggestion clearing, accepted-suggestion history, and refresh reindex triggering.
- Keep `LibraryView` responsible for visible state, navigation, sheets, delete confirmation, refresh animation, and route fetches.
- Keep all touched files under 500 LOC.
- Run focused search unit tests, simulator build, and Library/Search UI smoke attempt.

## Result

- Added `LibrarySearchServices`.
- Added `LibrarySearchServicesTests`.
- `LibraryView` now delegates search service setup and suggestion/history side effects.
