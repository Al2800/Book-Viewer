# Issue 045: Quote Tag Mutation Refactor

Status: closed

## Problem

`TagsView.swift` embedded quote-tag relationship mutation inside `AddTagToQuoteSheet`. Adding and removing tags manually updated both sides of the `Quote` / `Tag` relationship and touched `quote.dateModified`, but that invariant was only covered indirectly through UI and broader SwiftData integration tests.

The sheet should keep presentation, tag selection, sheet state, model-context save, and dismissal. The deterministic quote-tag mutation should live behind a focused tested module.

## Acceptance Criteria

- Characterize quote-tag add behaviour before production edits.
- Preserve adding the tag to `quote.tags`.
- Preserve adding the quote to `tag.quotes`.
- Preserve updating `quote.dateModified` when a tag is added.
- Characterize quote-tag remove behaviour.
- Preserve removing the tag from `quote.tags`.
- Preserve removing the quote from `tag.quotes`.
- Preserve updating `quote.dateModified` when a tag is removed.
- Keep `TagsView.swift` below 500 LOC.
- Run focused red-green tests for the extracted module.
- Run nearby tag/quote/collection tests.
- Run simulator build.
- Attempt tag UI smoke and record runner status.
- Update architecture and refactor-foundation docs.

## Result

- Added `BookQuotes/Features/Tags/QuoteTagMutation.swift`.
- Added `BookQuotesTests/Unit/Models/QuoteTagMutationTests.swift`.
- Updated `AddTagToQuoteSheet.addTag(_:)` and `removeTag(_:)` to delegate relationship mutation to `QuoteTagMutation`.
- Kept `TagsView.swift` responsible for presentation, sheet state, search/filtering, tag editing, model-context saves, and delete confirmation.

## LOC Result

- `BookQuotes/Features/Tags/TagsView.swift`: 448 LOC -> 440 LOC.
- `BookQuotes/Features/Tags/QuoteTagMutation.swift`: 21 LOC.
- `BookQuotesTests/Unit/Models/QuoteTagMutationTests.swift`: 32 LOC.

The file remains below the 500 LOC target. The new module earns its seam by concentrating a relationship invariant that would otherwise be duplicated or modified through UI code.

## Verification

- Focused red test confirmed the missing production module before implementation:
  - `BookQuotesTests/QuoteTagMutationTests`
- Focused green tests passed:
  - `BookQuotesTests/QuoteTagMutationTests`
- Nearby tag/quote/collection tests passed:
  - `BookQuotesTests/QuoteTagMutationTests`
  - `BookQuotesTests/TagModelTests`
  - `BookQuotesTests/QuoteModelTests`
  - `BookQuotesTests/CollectionTagRelationshipIntegrationTests`
- Simulator build passed.
- Tag UI smoke was attempted and failed before app assertions with XCTest runner initialization error:
  - `The test runner failed to initialize for UI testing. (Underlying Error: Timed out waiting for AX loaded notification)`

## Residual Risk / Next Slice

- `TagEditorDraft` now owns create/edit name normalization, save eligibility, new-tag creation, and existing-tag field mutation.
- `TagsPresentation` now owns tag search filtering and total-use summary.
- `TagsView` still owns tag creation, editing, deletion confirmation, model-context saves, sheet state, and tag row presentation.
- Visible tag-management behaviour still needs a healthy UI test runner to validate the full quote-detail add-tag route.
