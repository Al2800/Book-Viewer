# Book Cover Card Support Characterization

Date: 2026-06-30

Issue: `docs/issues/019-book-cover-card-support-refactor.md`

## Baseline Behaviour

This slice keeps the existing library book card/list row behaviour intact while extracting duplicated rendering support.

Book cover card behaviours:

- Grid card shows cover artwork when thumbnail data is present.
- Grid card shows a book placeholder and title when cover data is absent.
- Grid card overlays a quote count badge when the book has quotes.
- Grid card shows title, author, compact reading-status badge, and quote count text.
- Grid card keeps press animation, entrance animation, tap haptic, optional tap callback, context menu preview, and `bookCoverCard` accessibility identifier.

Book list row behaviours:

- List row shows small cover artwork or placeholder.
- List row shows title, author, full reading-status badge, quote count text, and chevron.
- List row keeps press animation, entrance animation, tap haptic, optional tap callback, context menu preview, and `bookListRow` accessibility identifier.

Shared context menu behaviours:

- Optional edit action uses "Edit Book" with pencil icon.
- Passive view-quotes action uses "View Quotes" with quote icon.
- Optional share action uses "Share" with system share icon.
- Optional delete action is destructive and uses "Delete Book" with trash icon.

## Characterization Used

Focused library UI baseline:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_ShowsSeededBooks
```

Result before edits:

- Failed before app assertions.
- XCTest UI runner error: `Timed out waiting for AX loaded notification`.
- Runtime before failure: `102.350` seconds.

Static characterization:

- Public view names and initializer surface remained unchanged: `BookCoverCard(book:onTap:onEdit:onShare:onDelete:)` and `BookListRow(book:onTap:onEdit:onShare:onDelete:)`.
- Accessibility identifiers remained unchanged: `AccessibilityIdentifiers.Library.bookCoverCard` and `AccessibilityIdentifiers.Library.bookListRow`.
- Existing caller coverage is through `LibraryTab.swift` and `LibraryManagementTests`.

## Extracted Module

- `BookCoverCardSupport.swift`: cover artwork rendering, quote count badge, reading-status badge, and context menu item construction.

## Non-Goals

- No change to Library navigation, SwiftData queries, book sorting/filtering, search, delete confirmation, or row/card caller APIs.
- No change to visible labels, icons, haptics, context menu preview, or accessibility identifiers.
- No test edits to make the refactor pass.
