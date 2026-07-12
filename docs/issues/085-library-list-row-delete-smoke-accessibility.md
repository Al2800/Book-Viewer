# Issue 085: Library List Row Delete Smoke Accessibility

Status: `open`

Priority: medium

## Context

The recovered Library/Search XCUITest smoke ran successfully against current `main` on 2026-07-12, but `LibraryManagementTests.testLibrary_DeleteBook_ShowsConfirmation` skipped rather than asserting the delete confirmation.

The test switched to list view and then searched for a swipeable `library_book_list_row` as a cell, link, or other element. None appeared. In the same run, `LibraryManagementTests.testLibrary_TapBook_NavigatesToDetail` did find and tap a descendant matching `library_book_list_row`, reported by XCTest as an image.

This means the AX runner is healthy, but the delete-confirmation smoke is not giving a clean behavioral assertion for Library list rows.

Result bundle:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.12_07-19-37-+0100.xcresult
```

Observed outcome:

```text
Executed 6 tests, with 1 test skipped and 0 failures.
Skipped: LibraryManagementTests.testLibrary_DeleteBook_ShowsConfirmation
Reason: List rows unavailable for delete swipe
```

## Acceptance Criteria

- [ ] Characterize the current Library list row accessibility hierarchy after switching to list view.
- [ ] Decide whether `library_book_list_row` should identify the swipeable row container rather than a child image.
- [ ] Make the production accessibility shape or the test target precise enough for swipe-to-delete to exercise the real row.
- [ ] `LibraryManagementTests.testLibrary_DeleteBook_ShowsConfirmation` passes without `XCTSkip`.
- [ ] Re-run the focused Library/Search UI smoke and record the result.

## Refactor Impact

Likely areas:

- `BookQuotes/Features/Library/LibraryBooksSectionViews.swift`
- `BookQuotes/Features/Library/BookCoverCard.swift`
- `BookQuotesUITests/Flows/LibraryManagementTests.swift`

Do not weaken the test to pass by skipping the behavior. The user-visible behavior to preserve is list-mode swipe delete followed by the destructive confirmation dialog.
