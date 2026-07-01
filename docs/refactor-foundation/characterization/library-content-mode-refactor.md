# Library Content Mode Refactor Characterization

Date: 2026-06-30

## Scope

This slice characterized the top-level content decision in `LibraryView`: search results, empty library state, or normal library browsing.

The intent was not to change Library UI. It was to move the deterministic content-mode rule behind a tested module so future search, empty-state, and Library browsing changes start from a precise seam.

## Characterized Behavior

- Active search with non-empty text shows search results, even when the Library has no books.
- Active search with empty text falls through to empty Library when there are no books.
- Inactive search shows the normal Library when books exist, even if stale search text remains in state.
- Inactive search shows empty Library when no books exist.

## Red Step

Added `LibraryContentModeTests`.

The first focused run failed because `LibraryContentMode` did not exist, confirming the test target was exercising the missing production module.

## Refactor

- Added `LibraryContentMode`.
- Replaced the inline `if/else` content branch in `LibraryView` with an explicit switch over `LibraryContentMode`.
- Kept SwiftData queries, search service setup, navigation, empty-state view, search-results view, and Library browsing presentation in their existing owners.

## Verification

See `docs/refactor-foundation/verification/2026-06-30-library-content-mode-refactor.md`.
