# Issue 062: Library View Mode Refactor

Status: `closed`

## Context

`LibraryTab.swift` is already below the 500 LOC target, but `LibraryView` still defined the grid/list mode enum that extracted Library modules consumed. That made `LibraryOverviewViews` and `LibraryBooksSectionViews` depend back on the root view type.

The useful refactor pressure here is dependency direction: extracted Library modules should depend on a Library feature seam, not on `LibraryView`.

## Acceptance Criteria

- [x] Characterize the current grid/list stored values and presentation strings before changing the root view.
- [x] Preserve the `@AppStorage("libraryViewMode")` raw values `grid` and `list`.
- [x] Preserve the SF Symbol names used by the toolbar/control/summary UI.
- [x] Preserve the summary labels `Grid View` and `List View`.
- [x] Move view-mode presentation behaviour out of `LibraryView`.
- [x] Update `LibraryOverviewViews` and `LibraryBooksSectionViews` to depend on the Library feature seam.
- [x] Keep `LibraryTab.swift` below 500 LOC.
- [x] Register new source and tests in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused Library view-mode tests when the local Xcode runner is healthy.
- [x] Run Library simulator smoke when CoreSimulatorService is available.

## Implementation

- Added `BookQuotes/Features/Library/LibraryViewMode.swift`.
- Added `BookQuotesTests/Unit/Library/LibraryViewModeTests.swift`.
- Removed the nested `LibraryView.ViewMode` enum from `LibraryTab.swift`.
- Updated `LibrarySummaryCard`, `LibraryViewModeControl`, and `LibraryBooksSection` to use `LibraryViewMode`.
- Reused `LibraryViewMode.systemImageName` and `LibraryViewMode.summaryText` instead of repeating grid/list conditionals in views.

## LOC Impact

- `BookQuotes/App/LibraryTab.swift`: 384 LOC -> 378 LOC.
- `BookQuotes/Features/Library/LibraryViewMode.swift`: 24 LOC.
- `BookQuotes/Features/Library/LibraryBooksSectionViews.swift`: 103 LOC.
- `BookQuotes/Features/Library/LibraryOverviewViews.swift`: 298 LOC.
- `BookQuotesTests/Unit/Library/LibraryViewModeTests.swift`: 21 LOC.

## Verification

- Passed:
  - `git diff --check`
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - LOC check for touched files.
  - Focused Library/Quote Detail characterization gate on 2026-07-01:
    - 78 tests executed.
    - 0 failures.
    - Included `LibraryViewModeTests`, nearby Library seams, and Book/Quote model tests.
  - Broad unit gate on 2026-07-01:
    - 548 tests executed.
    - 0 failures.
  - Manual seeded/mock-camera simulator smoke:
    - App launched with `--uitesting --preload-library-test-data --mock-camera`.
    - Screenshot showed seeded Library data with 3 books and 6 quotes.
    - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

XCUITest Library UI automation remains tracked separately by issue 081.

## Follow-Up

- Future grid/list storage or presentation changes should start in `LibraryViewModeTests`.
- `LibraryView` still owns search lifecycle, sheet state, delete persistence, refresh, and navigation orchestration.
