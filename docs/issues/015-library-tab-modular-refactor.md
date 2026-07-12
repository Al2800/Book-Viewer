# Library Tab Modular Refactor

Status: `in_progress`

Priority: high

## Problem

`LibraryTab.swift` was 807 LOC and mixed the tab shell, library screen orchestration, search service setup, book/quote navigation, deletion/edit/add sheets, summary cards, empty-state presentation, and reusable library rows.

The Library tab is the entry point for browsing, search, book detail, quote detail, and later feature additions. It needs clearer seams before new library features or bug fixes are added.

## Acceptance Criteria

- [x] Current seeded-library display, book-count marker, book-detail navigation, delete confirmation, search results, and search-result navigation are characterized before production edits.
- [x] Existing UI tests remain unchanged for this slice; production code must preserve the tested behaviour.
- [x] Extracted modules own real presentation behaviour, not single-line pass-through wrappers.
- [x] `LibraryTab.swift` moves below 500 LOC.
- [x] Existing accessibility identifiers for book cards, list rows, empty state, add button, and view-mode toggle remain stable.
- [x] Simulator UI smoke covers Library and Search paths after the extraction.
- [x] Verification docs record tests, LOC delta, and residual risk.

## Initial Target

Move Library overview presentation out of `LibraryTab.swift` while keeping navigation, search, persistence, delete, add/edit sheets, and refresh orchestration in `LibraryView`.

## Outcome So Far

2026-06-13:

- Added `BookQuotes/Features/Library/LibraryOverviewViews.swift`.
- Moved `EmptyLibraryView`, `LibrarySectionCard`, `LibrarySummaryCard`, `LibraryControlRow`, `LibraryActionRow`, `LibraryInfoRow`, and their private visual helpers into the Library feature folder.
- Reduced `LibraryTab.swift` from 807 LOC to 470 LOC.
- Kept `LibraryView` as the orchestration shell for search, navigation, fetches, refresh, delete, and add/edit sheet presentation.

2026-06-14:

- Added `BookQuotes/Features/Library/SearchResultsStateViews.swift`.
- Moved search empty, no-results, and error presentation out of `SearchResultsView`.
- Added `BookQuotes/Services/SQLiteStatement.swift`.
- Centralized SQLite statement lifecycle, string/int binding, stepping, and typed column reads for `SearchDatabase`.
- Added `BookQuotes/Services/SearchFTSQueryBuilder.swift`.
- Moved FTS query normalization and prefix construction out of `SearchDatabase`.
- Reduced the search slice files to:
  - `SearchResultsView.swift`: 353 LOC.
  - `SearchResultsStateViews.swift`: 218 LOC.
  - `SearchDatabase.swift`: 497 LOC.
  - `SQLiteStatement.swift`: 46 LOC.
  - `SearchFTSQueryBuilder.swift`: 24 LOC.
- Re-ran focused Search database/integration/UI characterization on the simulator without changing tests.

2026-06-30:

- Added `BookQuotes/Features/Library/LibraryBooksSectionViews.swift`.
- Moved the Library Books section, grid/list rendering, and view-mode segmented control out of `LibraryTab.swift`.
- Reduced `LibraryTab.swift` from 470 LOC to 393 LOC.
- Kept `LibraryView` as the orchestration shell for SwiftData queries, search lifecycle, navigation, add/edit/delete sheets, delete confirmation, and refresh.
- Focused Library UI smoke failed before and after this slice at UI runner AX initialization, so this extraction is build-verified but still lacks a clean UI assertion run.

2026-06-30 later:

- Added `BookQuotes/Features/Library/LibrarySearchServices.swift`.
- Moved paired search/suggestions setup and suggestion-history side effects out of `LibraryView`.
- Added `BookQuotesTests/Unit/Library/LibrarySearchServicesTests.swift`.
- Reduced `LibraryTab.swift` from 393 LOC to 386 LOC.
- Focused search unit characterization and simulator build passed.
- Focused Library/Search UI smoke still failed before app assertions at UI runner AX initialization.

2026-06-30 quote detail slice:

- Added `BookQuotes/Features/Library/QuoteDetailTextFormatter.swift`.
- Added `BookQuotesTests/Unit/Library/QuoteDetailTextFormatterTests.swift`.
- Moved the duplicated Quote Detail copy/share text contract out of `QuoteDetailView`.
- Reduced `QuoteDetailView.swift` from 449 LOC to 435 LOC.
- Focused formatter tests, nearby Library/model tests, and simulator build passed.
- Quote-detail UI smoke was attempted but failed before app assertions at UI runner AX initialization.

2026-06-30 search presentation slice:

- Added `BookQuotes/Features/Library/SearchResultsPresentation.swift`.
- Added `BookQuotesTests/Unit/Library/SearchResultsPresentationTests.swift`.
- Moved search result section visibility, row animation-delay, result-reset, and did-you-mean eligibility policy out of `SearchResultsView`.
- Reduced `SearchResultsView.swift` from 396 LOC to 365 LOC.
- Focused presentation tests, nearby search/library tests, and simulator build passed.
- Search UI smoke was attempted but failed before app assertions at UI runner AX initialization.

2026-06-30 content mode slice:

- Added `BookQuotes/Features/Library/LibraryContentMode.swift`.
- Added `BookQuotesTests/Unit/Library/LibraryContentModeTests.swift`.
- Moved the top-level search/empty/library content selection rule out of `LibraryView`.
- `LibraryTab.swift` remains below target at 387 LOC.
- Focused content-mode tests, nearby Library/Search tests, and simulator build passed.
- Library UI smoke was attempted but failed before app assertions at UI runner AX initialization.

2026-07-01 quote detail edit-save slice:

- Added `BookQuotes/Features/Library/QuoteDetailEditDraft.swift`.
- Added `BookQuotesTests/Unit/Library/QuoteDetailEditDraftTests.swift`.
- Moved deterministic Quote Detail edit-save field application out of `QuoteDetailView`.
- Kept `QuoteDetailView` responsible for UI state, model-context save, haptics, toolbar/sheet presentation, and dismissal.
- `QuoteDetailView.swift` remains below target at 437 LOC.
- Focused edit-draft tests, nearby Library/model tests, and simulator build passed.
- Quote-detail UI smoke was attempted but failed before app assertions at UI runner AX initialization.

2026-07-01 book detail quote presentation slice:

- Added `BookQuotes/Features/Library/BookDetailQuotePresentation.swift`.
- Added `BookQuotesTests/Unit/Library/BookDetailQuotePresentationTests.swift`.
- Moved deterministic Book Detail quote filtering, sorting, unique page count, and available marking filter calculation out of `BookDetailView`.
- Kept `BookDetailView` responsible for screen state, toolbar/sheet presentation, quote-capture presentation, delete persistence, haptics, navigation, and empty-state UI.
- Reduced `BookDetailView.swift` from 394 LOC to 370 LOC.
- Focused presentation tests, nearby Library/model tests, and simulator build passed.
- Book-detail UI smoke was attempted but failed before app assertions at UI runner AX initialization.

2026-07-01 book deletion prompt slice:

- Added `BookQuotes/Features/Library/BookDeletionPrompt.swift`.
- Added `BookQuotesTests/Unit/Library/BookDeletionPromptTests.swift`.
- Moved shared destructive book-deletion title/button/message copy out of `LibraryView` and `BookDetailView`.
- Kept model deletion, haptics, routing, dismissal, and dialog state in the existing views.
- `LibraryTab.swift` remains below target at 384 LOC.
- `BookDetailView.swift` remains below target at 377 LOC.
- Focused verification is pending because Xcode currently fails before compilation with the local `DARWIN_USER_CACHE_DIR` / CoreSimulator environment issue.

2026-07-01 quote detail edit-fields slice:

- Added `BookQuotes/Features/Library/QuoteDetailEditFields.swift`.
- Added `BookQuotesTests/Unit/Library/QuoteDetailEditFieldsTests.swift`.
- Moved deterministic quote-to-edit-field loading out of `QuoteDetailView.startEditing()`.
- Kept `QuoteDetailEditDraft` responsible for applying edited fields back to `Quote`.
- Kept `QuoteDetailView` responsible for UI state, focus, haptics, animation, model-context save, sheets, and dismissal.
- `QuoteDetailView.swift` remains below target at 438 LOC.
- Focused verification is pending because Xcode currently fails before compilation with the local `DARWIN_USER_CACHE_DIR` / CoreSimulator environment issue.

2026-07-01 quote deletion prompt slice:

- Added `BookQuotes/Features/Library/QuoteDeletionPrompt.swift`.
- Added `BookQuotesTests/Unit/Library/QuoteDeletionPromptTests.swift`.
- Moved Quote Detail destructive quote-deletion title/button/message copy out of `QuoteDetailView`.
- Kept quote deletion, model-context save, haptics, dismissal, and dialog state in `QuoteDetailView`.
- Focused verification is pending because Xcode currently fails before compilation with the local `DARWIN_USER_CACHE_DIR` / CoreSimulator environment issue.

2026-07-01 library view-mode slice:

- Added `BookQuotes/Features/Library/LibraryViewMode.swift`.
- Added `BookQuotesTests/Unit/Library/LibraryViewModeTests.swift`.
- Moved the grid/list stored values, SF Symbol names, and summary labels out of the nested `LibraryView.ViewMode` enum.
- Updated `LibraryOverviewViews` and `LibraryBooksSectionViews` to depend on the Library feature seam instead of the root view type.
- Reduced `LibraryTab.swift` from 384 LOC to 378 LOC.
- Focused verification is pending because Xcode currently fails before compilation with the local `DARWIN_USER_CACHE_DIR` / CoreSimulator environment issue.

2026-07-01 verification reconciliation:

- Focused Library/Quote Detail characterization gate passed after the Xcode runner recovered.
- 78 tests executed with 0 failures.
- The run covered the stale verification slices for:
  - `BookDeletionPromptTests`.
  - `QuoteDetailEditFieldsTests`.
  - `QuoteDeletionPromptTests`.
  - `LibraryViewModeTests`.
  - nearby Library seams and Book/Quote model tests.
- Broad unit gate remains green at 548 tests, 0 failures.
- Manual seeded/mock-camera simulator launch passed and showed seeded Library data with 3 books and 6 quotes.
- XCUITest UI automation still fails before app assertions and remains tracked by issue 081.

2026-07-12 home sections slice:

- Moved the Browse card (view-mode control, sort menu, camera-first add-book row), the Organize card (Collections/Tags navigation links), and the filtered-books empty card out of `LibraryTab.swift` into `LibraryOverviewViews.swift` as `LibraryBrowseSection`, `LibraryOrganizeSection`, and `LibraryFilteredBooksEmptyCard`.
- These sections had accreted in `LibraryView` during the July feature passes (library sorting, organize entry points, camera-first add book) and pushed the file back over target.
- Reduced `LibraryTab.swift` from 535 LOC to 456 LOC.
- Kept `LibraryView` as the orchestration shell for SwiftData queries, search lifecycle and index sync, navigation, add/edit/delete sheets, and refresh.
- Accessibility identifiers for the sort menu, collections row, tags row, and add-book button are unchanged.
- Also deduplicated the HTTP status-validation block repeated in three `ISBNLookupService` methods into a private `fetchLookupData(from:)` helper (489 -> 463 LOC); error mapping is byte-identical, so the hermetic playback tests characterize it unchanged.
- Verification pending on the Mac session: focused Library unit gate plus the now-recovered XCUITest Library/Search smoke (issue 081 closed).

2026-07-12 foundation and bug-fix slice (same branch):

- Unified the five parallel section-card implementations (`LibrarySectionCard`, `SettingsSectionCard`, `CaptureSectionCard`, `BookEditSectionCard`, `ExportView.exportSectionCard`) into one `SectionCard` in `DesignSystemChrome.swift`; 37 call sites migrated, old structs removed, no intended visual changes. Future design-system section work should target `SectionCard` only.
- Added `LibraryHomeSnapshot` (single pass over the library's quotes per render) to replace the three separate quote-graph walks in `LibraryView` (daily passage, summary count, index-sync change detection); container-backed unit tests added.
- Fixed a double-save window in `BookEditView`: the first-book milestone delays dismissal 2.2s while Save stayed enabled, allowing duplicate inserts.
- Fixed silently-dead taps on stale search results after deletions: the tap now resyncs the FTS index and re-runs the search.
- Quote share card is now rendered once when the share action is invoked rather than on every share-sheet body evaluation.
- Device follow-ups for the Mac session: two `.searchable` modifiers in one navigation stack (Library root + pushed Book Detail), dark-mode pass over camera chrome, batch-capture tray spacing.

## Residual Risk / Next Slice

- `LibraryContentMode` now owns deterministic selection between search results, empty library, and normal library browsing.
- `SearchResultsPresentation` now owns deterministic search presentation policy. Future behavioural search presentation changes should start there before editing `SearchResultsView`.
- `SearchResultsView.swift` is below the LOC target but still owns SwiftData row fetches and did-you-mean async task state. Further extraction should wait for a product-facing reason or stronger characterization seam.
- `LibraryView` no longer initializes search services directly; `LibrarySearchServices` owns paired service setup and suggestion/history side effects.
- `LibraryViewMode` now owns the Library grid/list stored values and presentation metadata; future mode-storage or view-mode label/icon changes should be characterized in `LibraryViewModeTests`.
- Library grid/list presentation is now isolated in `LibraryBooksSectionViews.swift`; future visible changes to book card/list browsing should first repair the Library UI runner path or add a lower-level presentation characterization seam.
- `QuoteDetailTextFormatter` now owns the Quote Detail copy/share text contract; future quote-detail action text changes should be characterized in `QuoteDetailTextFormatterTests`.
- `QuoteDetailEditDraft` now owns the Quote Detail edit-save field mutation contract; future edit-save field changes should be characterized in `QuoteDetailEditDraftTests`.
- `BookDetailQuotePresentation` now owns Book Detail quote filtering, sorting, unique page count, and available marking filters; future book-detail quote list behavior should start there before changing `BookDetailView`.
- `BookDeletionPrompt` now owns shared destructive book-deletion copy; future Library or Book Detail deletion wording changes should start there before changing SwiftUI dialog call sites.
- `QuoteDetailEditFields` now owns the Quote Detail edit-load field mapping; future edit-mode initialization changes should be characterized there before changing `QuoteDetailView`.
- `QuoteDeletionPrompt` now owns Quote Detail destructive quote-deletion copy; future quote deletion wording changes should start there before changing SwiftUI dialog call sites.
